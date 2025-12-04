import { formatStructure, formatStructureToObject, ValueBaseValues } from "./DataFormat";

export function resolveStructure(
	structure: Instance[],
	...otherStructure: Record<string, ValueBaseValues>[]
): Record<string, ValueBaseValues> {
	const formattedStructure = formatStructure(formatStructureToObject(structure));
	for (let i = 1; i < otherStructure.size(); i++)
		for (const [name, value] of pairs(otherStructure[i])) {
			formattedStructure[name] = value;
		}

	return formattedStructure;
}
