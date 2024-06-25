export type TaskLogger = {
	error: (...string) -> (),
	info: (...string) -> (),
}
export type TaskEnv = {
	logger: TaskLogger,
	execute: (program: string, ...string) -> number,
}

return "<shared>"
