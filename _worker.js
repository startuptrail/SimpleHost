// Cloudflare Pages Advanced Mode worker. Place at the published output root.
// All paths other than / are served unchanged from static assets.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/" || url.pathname === "") {
      url.pathname = "/install.sh";
      return env.ASSETS.fetch(new Request(url.toString(), request));
    }
    return env.ASSETS.fetch(request);
  }
};
