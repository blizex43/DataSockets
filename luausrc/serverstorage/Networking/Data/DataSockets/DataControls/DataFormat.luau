-- Compiled with roblox-ts v3.0.0
local color3ToTable, cFrameToTable
local function formatStructure(structure)
	local exportedStructure = {}
	for instanceName, instanceValue in pairs(structure) do
		if { string.find(instanceValue.ClassName, "Value") } == nil then
			continue
		end
		local outputValue
		local _exp = instanceValue.ClassName
		repeat
			if _exp == "Color3Value" then
				outputValue = color3ToTable(instanceValue.Value)
				break
			end
			if _exp == "CFrameValue" then
				outputValue = cFrameToTable(instanceValue.Value)
				break
			end
			outputValue = instanceValue.Value
			break
		until true
		exportedStructure[instanceName] = outputValue
	end
	return exportedStructure
end
local function formatStructureToObject(structure)
	local exportedStructure = {}
	for i = 1, #structure - 1 do
		local structureChild = structure[i + 1]
		exportedStructure[structureChild.Name] = structureChild
	end
	return exportedStructure
end
local function serializeData(deserializedData)
	for index, value in pairs(deserializedData) do
		local dataType = typeof(value)
		repeat
			if dataType == "CFrame" then
				deserializedData[index] = cFrameToTable(value)
				break
			end
			if dataType == "Color3" then
				deserializedData[index] = color3ToTable(value)
				break
			end
			break
		until true
	end
	return deserializedData
end
local tableToColor3, tableToCFrame
local function deserializeData(serializedData)
	for index, value in pairs(serializedData) do
		if typeof(value) ~= "table" or (value.Red == nil and value.Position == nil) then
			continue
		end
		serializedData[index] = nil
		if value.Red ~= nil then
			serializedData[index] = tableToColor3(value)
		elseif value.Position ~= nil then
			serializedData[index] = tableToCFrame(value)
		end
	end
	return serializedData
end
function tableToColor3(object)
	return Color3.new(object.Red / 255, object.Green / 255, object.Blue / 255)
end
function cFrameToTable(cFrame)
	return {
		Position = {
			X = cFrame.Position.X,
			Y = cFrame.Position.Y,
			Z = cFrame.Position.Z,
		},
		RightVector = {
			X = cFrame.RightVector.X,
			Y = cFrame.RightVector.Y,
			Z = cFrame.RightVector.Z,
		},
		UpVector = {
			X = cFrame.UpVector.X,
			Y = cFrame.UpVector.Y,
			Z = cFrame.UpVector.Z,
		},
		LookVector = {
			X = cFrame.LookVector.X,
			Y = cFrame.LookVector.Y,
			Z = cFrame.LookVector.Z,
		},
	}
end
function tableToCFrame(object)
	local p = object.Position
	local r = object.RightVector
	local u = object.UpVector
	local l = object.LookVector
	return CFrame.new(p.X, p.Y, p.Z, r.X, u.X, -l.X, r.Y, u.Y, -l.Y, r.Z, u.Z, -l.Z)
end
local function color3ToRGB(color3)
	return { math.floor(color3.R * 255), math.floor(color3.G * 255), math.floor(color3.B * 255) }
end
function color3ToTable(color3)
	local _binding = color3ToRGB(color3)
	local Red = _binding[1]
	local Green = _binding[2]
	local Blue = _binding[3]
	return {
		Red = Red,
		Green = Green,
		Blue = Blue,
	}
end
return {
	formatStructure = formatStructure,
	formatStructureToObject = formatStructureToObject,
	serializeData = serializeData,
	deserializeData = deserializeData,
}
