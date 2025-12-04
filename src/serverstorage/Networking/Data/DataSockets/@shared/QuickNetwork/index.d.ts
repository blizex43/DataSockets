// QuickNetwork.d.ts
// Type declarations for your Lua QuickNetwork module

declare namespace QuickNetwork {
	/**
	 * Represents a saved data object returned by DataNetwork:LoadDataAsync.
	 */
	interface DataObject {
		[key: string | number]: unknown;

		MetaData: {
			Key: string | number;
			Loaded: boolean;
			Updated: boolean;
			Cleared: boolean;
			BoundToClear: boolean;
			Backup: boolean;
			AutoSaving: boolean;
			SessionJobTime: number;
			SessionLockFree: boolean;

			CombinedKeys: Record<string | number, boolean>;
			CombinedDataStores: Record<string, boolean>;

			DataNetwork: QuickNetwork.DataNetwork;

			ReleaseTagJobId?: string;
		};

		// Signals created dynamically unless readOnly = true
		/**
		 * Fired when values change.
		 * Fire(key, value)
		 */
		ListenToUpdate: Signal<[key: string | number, value: unknown, parent?: object]>;
		/**
		 * Fired after Save().
		 * Fire(isBackup: boolean)
		 */
		ListenToSave: Signal<[isBackup: boolean]>;

		/**
		 * Fired after Wipe().
		 * Fire(isBackup: boolean)
		 */
		ListenToWipe: Signal<[isBackup: boolean]>;

		/**
		 * Fired when Clear() happens.
		 */
		_ListenToClear: Signal<[]>;

		/**
		 * Replace a key's value.
		 */
		Set(key: string | number, value: unknown): void;

		/**
		 * Sets a nested field.
		 * Example: data:SetTable(100, "Inventory", "Coins")
		 */
		SetTable(value: unknown, ...path: string[]): void;

		/**
		 * True if not cleared.
		 */
		IsActive(): boolean;

		/**
		 * True if this is backup data.
		 */
		IsBackup(): boolean;

		/**
		 * Save data.
		 * forceSave = save even if not updated.
		 */
		Save(forceSave?: boolean): void;

		/**
		 * Clears backup flag.
		 */
		ClearBackup(): void;

		/**
		 * Mark the data as cleared and save.
		 */
		Clear(): void;

		/**
		 * Reconciles missing keys with default template.
		 */
		Reconcile(): void;

		/**
		 * Completely wipes the data record.
		 */
		Wipe(forceWipe?: boolean): void;

		/**
		 * Merge values from other keys on the same DataNetwork.
		 */
		CombineKeysAsync(...keys: (string | number)[]): Promise<void>;

		/**
		 * Merge values from other datastores.
		 */
		CombineDataStoresAsync(...storeNames: string[]): Promise<void>;
	}

	/**
	 * Signal type used internally.
	 */
	interface Signal<T = unknown> {
		Connect(fn: (...args: T[]) => void): RBXScriptConnection;
		Fire(...args: T[]): void;
		Wait(): T[];
		Disconnect(): void;
	}

	/**
	 * Represents a single DataNetwork instance returned by QuickNetwork.GetDataNetwork().
	 */
	interface DataNetwork {
		/**
		 * Loads or returns cached data for a key.
		 */
		LoadDataAsync(
			key: string | number,
			loadMethod?: "cancel" | "steal" | string,
			readOnly?: boolean,
		): DataObject | undefined;

		/**
		 * Returns cached data synchronously.
		 */
		GetCachedData(key: string | number): DataObject | undefined;

		/**
		 * Default template used when no data exists.
		 */
		DefaultDataTemplate: object;

		/**
		 * Fired when corrupted data is loaded.
		 */
		DataCorruptionLoadSignal: Signal<[key: string | number, reason: string]>;

		/**
		 * Fired on loading errors.
		 */
		DataErrorLoadSignal: Signal<[key: string | number, reason: string]>;
	}

	/**
	 * Retrieves or creates a DataNetwork for a given name.
	 */
	function GetDataNetwork(name: string, defaultDataTemplate: object, mock?: boolean): DataNetwork;
}

export = QuickNetwork;
