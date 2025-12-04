export interface Connection {
	Disconnect(): void;
	IsConnected: boolean;
}

export interface SignalType<T extends unknown[] = unknown[]> {
	Connect(listener: (...args: T) => void): Connection;
	Wait(): LuaTuple<T>;
	Fire(...args: T): void;
	FireUntil(continueCallback: () => boolean, ...args: T): void;
}

export interface ServerSignalType<T extends unknown[] = unknown[]> {
	Connect(listener: (player: Player, ...args: T) => void): Connection;
	Wait(): LuaTuple<T>;
	Fire(...args: T): void;
	FireUntil(continueCallback: () => boolean, ...args: T): void;
}

// This is the signature you want for New()
export declare function New<T extends unknown[]>(): SignalType<T>;
