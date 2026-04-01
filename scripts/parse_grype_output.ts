import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

type JsonValue =
	| string
	| number
	| boolean
	| null
	| JsonValue[]
	| { [key: string]: JsonValue };

type JsonObject = { [key: string]: JsonValue };

const CRITICAL_SEVERITIES = new Set(['CRITICAL', 'HIGH']);

const [, , filePath] = process.argv;

if (!filePath) {
	console.error('Usage: tsx scripts/parse_grype_output.ts <path-to-json-file>');
	process.exit(1);
}

const resolvedPath = resolve(filePath);

function loadJsonFile(pathToFile: string): JsonValue {
	const contents = readFileSync(pathToFile, 'utf8');
	return JSON.parse(contents) as JsonValue;
}

let parsedJson: JsonValue;

try {
	parsedJson = loadJsonFile(resolvedPath);
} catch (error) {
	console.error(`Failed to read or parse JSON file at ${resolvedPath}`);
	console.error(error);
	process.exit(1);
}

function isJsonObject(value: JsonValue | undefined): value is JsonObject {
	return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function asString(value: JsonValue | undefined): string | undefined {
	return typeof value === 'string' ? value : undefined;
}

if (!isJsonObject(parsedJson)) {
	console.error('Unexpected JSON structure: root element is not an object.');
	process.exit(1);
}

const matchesValue = parsedJson.matches;

if (!Array.isArray(matchesValue)) {
	console.error('Unexpected JSON structure: "matches" is missing or not an array.');
	process.exit(1);
}

let matchCount = 0;

for (const entry of matchesValue) {
	if (!isJsonObject(entry)) {
		continue;
	}

	const vulnerability = isJsonObject(entry.vulnerability) ? entry.vulnerability : undefined;
	const severity = asString(vulnerability?.severity)?.toUpperCase();

	if (!severity || !CRITICAL_SEVERITIES.has(severity)) {
		continue;
	}

	matchCount += 1;
	const vulnerabilityId = asString(vulnerability?.id) ?? 'Unknown ID';
	const vulnerabilityDescription =
		asString(vulnerability?.description) ?? 'No description provided.';

	const artifact = isJsonObject(entry.artifact) ? entry.artifact : undefined;
	const locationsValue = artifact?.locations;

	const resolvedPaths = Array.isArray(locationsValue)
		? locationsValue
				.map((location) =>
					isJsonObject(location) ? asString(location.path) ?? '(missing path)' : undefined,
				)
				.filter((path): path is string => typeof path === 'string')
		: [];

	const pathsToPrint = resolvedPaths.length > 0 ? resolvedPaths : ['(no locations provided)'];

	console.log('---');
	console.log(`vulnerability.id: ${vulnerabilityId}`);
	console.log(`vulnerability.description: ${vulnerabilityDescription}`);
	console.log('artifact.locations[*].path:');
	for (const path of pathsToPrint) {
		console.log(`  - ${path}`);
	}
}

if (matchCount === 0) {
	console.log('No Critical or High severity matches found.');
}
