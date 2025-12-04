// Trove.d.ts
// Type definitions for Stephen Leitnick's Trove module

declare namespace TroveTypes {
	/**
	 * Allowed cleanup methods Trove can call on objects.
	 */
	type CleanupMethod = "Destroy" | "Disconnect" | string; // For custom cleanup methods on tables

	/**
	 * Types Trove accepts in `Add()`.
	 */
	type Addable = Instance | RBXScriptConnection | Callback | thread | object; // Tables w/ Destroy/Disconnect
}

/**
 * Represents a Trove object that manages cleanup of instances,
 * connections, functions, coroutines, promises, and custom objects.
 */
declare class Trove {
	/**
	 * Constructs a new Trove.
	 */
	constructor();

	/**
	 * Creates a new Trove and adds it to this Trove.
	 */
	Extend(): Trove;

	/**
	 * Clones an Instance and adds the clone to the Trove.
	 */
	Clone<T extends Instance>(instance: T): T;

	/**
	 * Constructs an object from a class or function and adds it to the Trove.
	 */
	Construct<T>(classObject: { new (...args: never[]): T } | ((...args: never[]) => T), ...args: unknown[]): T;

	/**
	 * Connects a function to a signal and adds the connection to the Trove.
	 */
	Connect(signal: RBXScriptSignal, fn: (...args: unknown[]) => void): RBXScriptConnection;

	/**
	 * Wraps BindToRenderStep and ensures cleanup unbinds it.
	 */
	BindToRenderStep(name: string, priority: number, fn: (dt: number) => void): void;

	/**
	 * Adds a Promise to the Trove, automatically canceling it on cleanup.
	 * (Works only with roblox-lua-promise v4)
	 */
	AddPromise<T>(promise: Promise<T>): Promise<T>;

	/**
	 * Adds an object to be cleaned when the Trove is destroyed.
	 */
	Add<T extends TroveTypes.Addable>(object: T, cleanupMethod?: TroveTypes.CleanupMethod): T;

	/**
	 * Removes and immediately cleans up a tracked object.
	 */
	Remove(object: unknown): boolean;

	/**
	 * Cleans all objects stored in the Trove.
	 */
	Clean(): void;

	/**
	 * Alias for Clean().
	 */
	Destroy(): void;

	/**
	 * Attaches cleanup behavior to an Instance when destroyed.
	 */
	AttachToInstance(instance: Instance): RBXScriptConnection;

	// ======== Internal Methods (private in behavior, public in TS) ========

	/**
	 * @hidden Internal: used to remove & cleanup stored objects.
	 */
	_findAndRemoveFromObjects(object: unknown, cleanup: boolean): boolean;

	/**
	 * @hidden Internal: invokes correct cleanup based on object type.
	 */
	_cleanupObject(object: unknown, cleanupMethod: TroveTypes.CleanupMethod): void;

	// Internal state markers (never used directly in TS)
	private _objects: Array<[unknown, TroveTypes.CleanupMethod]>;
	private _cleaning: boolean;
}

export = Trove;
