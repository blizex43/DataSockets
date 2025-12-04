// Typescript Literals
export class asyncConsole {
	constructor() {}
	log(...msg: unknown[]): void {
		return print(...msg);
	}
}
const console = new asyncConsole();
export { console };
