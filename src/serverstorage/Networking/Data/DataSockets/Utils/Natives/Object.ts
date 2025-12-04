import { DynamicRecord } from "./Types";
import { Error } from "./Functions";
export function Object(obj: DynamicRecord) {
	return {
		/**
		 * Returns an array containing all enumerable keys in the given object.
		 * Works on plain objects, maps returned from Roblox-TS, or any table-like structure.
		 *
		 * @param obj - The object to read keys from.
		 * @returns A list of keys stored in the object.
		 */
		keys: () => {
			const keys = [];
			for (const [key] of pairs(obj)) keys.push(key);
			return keys;
		},
		/**
		 * Returns an array containing all enumerable values in the given object.
		 * Useful when you only care about stored values and not their key names.
		 *
		 * @param obj - The object to read values from.
		 * @returns A list of values stored in the object.
		 */
		values: () => {
			const values = [];
			for (const [, value] of pairs(obj)) values.push(value);
			return values;
		},
		/**
		 * Returns an array of key–value pairs for every enumerable property in the object.
		 * Each element is a tuple containing `[key, value]`, matching standard JavaScript behavior.
		 *
		 * @param obj - The object to read entries from.
		 * @returns An array of `[key, value]` tuples representing the object's contents.
		 */
		entries: () => {
			const object: DynamicRecord = {};
			for (const [key, value] of pairs(obj)) object[key] = value;
			return object;
		},

		/**
		 * Returns a boolean if the input is included within the object
		 * @param obj - The object to read entries from.
		 * @param key - What string to find within the keys of the object
		 * @returns boolean if the key is found.
		 */
		hasOwn: (key: string): boolean => {
			if (!obj) new Error(`${obj} is not an object.`);
			for (const [k] of pairs(obj)) {
				if (k === key) return true;
			}
			return false;
		},
	};
}
