/**
 * Structured JSON output formatter for markdownlint-cli2.
 *
 * The Neovim integration consumes this output to publish
 * markdownlint findings through vim.diagnostic.
 */

export default function formatter({ results, logMessage }) {
  const diagnostics = results.map((result) => {
    const range = result.errorRange ?? [];

    return {
      fileName: result.fileName,
      lineNumber: result.lineNumber,
      column: range[0] ?? null,
      length: range[1] ?? null,
      severity: result.severity,
      ruleNames: result.ruleNames ?? [],
      ruleDescription: result.ruleDescription ?? null,
      errorDetail: result.errorDetail ?? null,
      errorContext: result.errorContext ?? null,
    };
  });

  logMessage(JSON.stringify(diagnostics));
}
