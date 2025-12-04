export type Basic = string | number;
export type Dynamic =
	| undefined
	| boolean
	| Basic
	| DynamicRecord
	| Map<Basic, Dynamic>
	| RoTypes
	| Record<Basic, RoTypes>;
export type RoTypes = Instance | Enum | Vector3;
export interface DynamicRecord {
	[key: string]: Dynamic;
}
