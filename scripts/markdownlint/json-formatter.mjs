

/**
 * Structured JSON output formatter for markdownlint-cli2.
 *
 * The Neovim integration consumes this output to publish
 * markdownlint findings through vim.diagnostic.
 */

/**
 * @param {{
 *   results: Array<{
 *     fileName: string,
 *     lineNumber: number,
 *     errorRange?: [number, number],
 *     severity: number,
 *     ruleNames?: string[],
 *     ruleDescription?: string,
 *     errorDetail?: string,
 *     errorContext?: string
 *   }>,
 *   logMessage: (message: string) => void
 * }} params
 */
export default function formatter({ results, logMessage }) {
  const diagnostics = results.map((result) => {
    const [column = null, length = null] = result.errorRange ?? [];

    return {
      fileName: result.fileName,
      lineNumber: result.lineNumber,
      column,
      length,
      severity: result.severity,
      ruleNames: result.ruleNames ?? [],
      ruleDescription: result.ruleDescription ?? null,
      errorDetail: result.errorDetail ?? null,
      errorContext: result.errorContext ?? null,
    };
  });

  logMessage(JSON.stringify(diagnostics));
}
