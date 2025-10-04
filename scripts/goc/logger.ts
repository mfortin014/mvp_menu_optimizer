export const logger = {
  notice: (msg: string) => console.log(`::notice::${msg}`),
  warn:   (msg: string) => console.log(`::warning::${msg}`),
  error:  (msg: string) => console.log(`::error::${msg}`),
};
