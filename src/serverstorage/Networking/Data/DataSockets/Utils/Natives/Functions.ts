/**
 * setTimeout in TypeScript functions identically to its JavaScript counterpart,
 * scheduling a function to execute after a specified delay in milliseconds.
 * TypeScript, being a superset of JavaScript, automatically transcompiles
 * setTimeout calls into JavaScript for execution.
 * @param func - Input the function for it too call after waiting the set time.
 * @param waitTime - Input the amount of time in milliseconds to wait for the thread to execute.
 * @returns a thread that will run after the set amount of time.
 **/
export function setTimeout(func: Callback, waitTime: number = 0): thread {
	return task.delay(waitTime / 1000, func);
}

/**
 * clearTimeout prevents the scheduled function from executing if it hasn't already
 * @param thread - Input the thread that you've started for it to cancel
 **/
export function clearTimeout(
	thread: thread,
): [success: false, errorValue: unknown] | [success: true, errorValue: never] {
	return coroutine.close(thread);
}

export class Error {
	constructor(msg: string) {
		return error(`${msg}\n${debug.traceback()}`);
	}
}

export class Warn {
	constructor(msg: string) {
		warn(`${msg}\n${debug.traceback()}`);
	}
}
