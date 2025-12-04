import { DataObject } from "../@shared/QuickNetwork";

export type ValueBaseValues = number | string | Color3 | CFrame | boolean | object;
export type SerialValues = number | string | boolean | object;
export function formatStructure(structure: Record<string, ValueBase>): Record<string, ValueBaseValues> {
	const exportedStructure: Record<string, ValueBaseValues> = {};
	for (const [instanceName, instanceValue] of pairs(structure)) {
		if (instanceValue.ClassName.find("Value") === undefined) continue;
		let outputValue: ValueBaseValues;
		switch (instanceValue.ClassName) {
			case "Color3Value":
				outputValue = color3ToTable(instanceValue.Value as Color3);
				break;
			case "CFrameValue":
				outputValue = cFrameToTable(instanceValue.Value as CFrame);
				break;
			default:
				outputValue = instanceValue.Value as ValueBaseValues;
				break;
		}
		exportedStructure[instanceName] = outputValue;
	}
	return exportedStructure;
}

export function formatStructureToObject(structure: Instance[]): Record<string, ValueBase> {
	const exportedStructure: Record<string, ValueBase> = {};
	for (let i = 1; i < structure.size(); i++) {
		const structureChild = structure[i];
		exportedStructure[structureChild.Name] = structureChild as ValueBase;
	}
	return exportedStructure;
}

export function serializeData(deserializedData: DataObject) {
	for (const [index, value] of pairs(deserializedData)) {
		const dataType = typeOf(value);
		switch (dataType) {
			case "CFrame":
				deserializedData[index] = cFrameToTable(value as CFrame);
				break;
			case "Color3":
				deserializedData[index] = color3ToTable(value as Color3);
				break;
			default:
				break;
		}
	}
	return deserializedData;
}

export function deserializeData(serializedData: DataObject) {
	for (const [index, value] of pairs(serializedData)) {
		if (
			typeOf(value) !== "table" ||
			((value as Record<string, number>).Red === undefined &&
				(value as Record<string, number>).Position === undefined)
		)
			continue;
		delete serializedData[index];
		if ((value as Record<string, number>).Red !== undefined)
			serializedData[index] = tableToColor3(value as Record<string, number>);
		else if ((value as Record<string, number>).Position !== undefined)
			serializedData[index] = tableToCFrame(value as Record<string, Record<string, number>>);
	}
	return serializedData;
}

function tableToColor3(object: Record<string, number>): Color3 {
	return new Color3(object.Red / 255, object.Green / 255, object.Blue / 255);
}

function cFrameToTable(cFrame: CFrame) {
	return {
		Position: {
			X: cFrame.Position.X,
			Y: cFrame.Position.Y,
			Z: cFrame.Position.Z,
		},
		RightVector: {
			X: cFrame.RightVector.X,
			Y: cFrame.RightVector.Y,
			Z: cFrame.RightVector.Z,
		},
		UpVector: {
			X: cFrame.UpVector.X,
			Y: cFrame.UpVector.Y,
			Z: cFrame.UpVector.Z,
		},
		LookVector: {
			X: cFrame.LookVector.X,
			Y: cFrame.LookVector.Y,
			Z: cFrame.LookVector.Z,
		},
	};
}

function tableToCFrame(object: Record<string, Record<string, number>>): CFrame {
	const p = object.Position;
	const r = object.RightVector;
	const u = object.UpVector;
	const l = object.LookVector;

	return new CFrame(p.X, p.Y, p.Z, r.X, u.X, -l.X, r.Y, u.Y, -l.Y, r.Z, u.Z, -l.Z);
}

function color3ToRGB(color3: Color3): [number, number, number] {
	return [math.floor(color3.R * 255), math.floor(color3.G * 255), math.floor(color3.B * 255)];
}

function color3ToTable(color3: Color3): Record<string, number> {
	const [Red, Green, Blue] = color3ToRGB(color3);
	return { Red, Green, Blue };
}
