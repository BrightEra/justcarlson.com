import type { AstroIntegration } from "astro";
import { execSync } from "child_process";

export default function buildValidator(): AstroIntegration {
  return {
    name: "build-validator",
    hooks: {
      "astro:build:done": async ({ dir, pages, logger }) => {
        const distPath = dir.pathname;

        logger.info("Running build validation...");

        // Identity leak detection
        // Search for "steipete" or "Peter Steinberger" (case-insensitive) in dist/
        try {
          const grepResult = execSync(
            `grep -rli "steipete\\|peter steinberger" "${distPath}" 2>/dev/null || true`,
            { maxBuffer: 10 * 1024 * 1024, encoding: "utf-8" }
          );

          const leakedFiles = grepResult.trim().split("\n").filter(Boolean);

          if (leakedFiles.length > 0) {
            logger.warn(`Identity leak detected in ${leakedFiles.length} file(s):`);
            leakedFiles.forEach((file) => {
              // Show relative path from dist for readability
              const relativePath = file.replace(distPath, "");
              logger.warn(`  - ${relativePath}`);
            });
          } else {
            logger.info("No identity leaks detected");
          }
        } catch (error) {
          // Log but don't fail - this is informational only
          logger.warn(`Identity leak check encountered an error: ${error}`);
        }

        // Critical page verification
        const criticalPages = ["/", "/about", "/posts"];
        const builtPaths = Array.from(pages).map((page) => page.pathname);

        const missingPages = criticalPages.filter((page) => {
          // Normalize page paths for comparison
          const normalizedPage = page === "/" ? "" : page.replace(/^\//, "");
          return !builtPaths.some(
            (built) => built === normalizedPage || built === normalizedPage + "/"
          );
        });

        if (missingPages.length > 0) {
          logger.warn(`Missing critical pages: ${missingPages.join(", ")}`);
        } else {
          logger.info("All critical pages present");
        }

        logger.info("Build validation complete");
      },
    },
  };
}
