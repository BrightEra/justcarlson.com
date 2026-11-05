// Widths must match `images.sizes` in vercel.json, or Vercel returns 400.
type VercelImageWidth = 256 | 640 | 1080 | 2048;

const isLocal = (src: string) => src.startsWith("/") && !src.startsWith("//");

/** Resize a local image with Vercel Image Optimization. Remote URLs pass through. */
export function vercelImage(src: string, width: VercelImageWidth, quality = 75): string {
  if (!isLocal(src)) return src;
  return `/_vercel/image?url=${encodeURIComponent(src)}&w=${width}&q=${quality}`;
}

/** `srcset` of optimized widths, or undefined for remote URLs. */
export function vercelSrcset(src: string, widths: VercelImageWidth[]): string | undefined {
  if (!isLocal(src)) return undefined;
  return widths.map((w) => `${vercelImage(src, w)} ${w}w`).join(", ");
}

/**
 * `onerror` handler that loads the original file.
 * `/_vercel/image` exists only on Vercel, so `astro dev` and `astro preview` need it.
 */
export function originalImageFallback(src: string): string {
  return `this.onerror=null;this.removeAttribute('srcset');this.src=${JSON.stringify(src)};`;
}
