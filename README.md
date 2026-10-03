# webR Shiny Apps

R Shiny apps that run entirely in the web browser with [Shinylive](https://posit-dev.github.io/r-shinylive/) and [webR](https://docs.r-wasm.org/webr/latest/), hosted on GitHub Pages.
No server is involved, so data uploaded to an app never leave the user's computer.

<https://ksatohds.github.io/webR/>

| App | URL | Source |
|---|---|---|
| CART (classification and regression trees) | <https://ksatohds.github.io/webR/CART/> | `apps/CART/` |

## Layout

| Path | Contents |
|---|---|
| `apps/<app>/` | App source (`ui.R`, `server.R` and any files bundled with the app) |
| `site/` | Files copied verbatim into `docs/` (the index page `index.html` and the example data) |
| `data-raw/` | Script that creates the example data, and bibliographic records of their sources |
| `tests/` | Script that creates test data for checking the apps |
| `build.R` | Exports all apps into `docs/` |
| `docs/` | The published site (GitHub Pages: branch `main`, folder `/docs`). **Do not edit by hand.** |

The webR runtime and the R packages under `docs/shinylive/` are shared by all apps.

## Build

Requires R and the CRAN package shinylive.

```bash
Rscript build.R          # all apps
Rscript build.R CART     # CART only
```

The packages an app uses are detected automatically, and their WebAssembly builds are bundled in `docs/shinylive/webr/packages/`.
If a locally installed package version differs from the WebAssembly build, a warning is shown, but the export still completes.

## Checking locally

`docs/` must be served over HTTP (it does not work from `file://`). To serve it under the same `/webR/` path as on GitHub Pages:

```bash
Rscript -e "httpuv::runServer('127.0.0.1', 7655, list(call = function(req) list(status = 404L, headers = list(), body = ''), staticPaths = list('/webR' = httpuv::staticPath('docs', indexhtml = TRUE))))"
```

Then open <http://localhost:7655/webR/CART/>.

After every rebuild, check that:

1. the browser console shows no errors while the packages are loaded;
2. a classification tree built from `tests/data/birthwt_jp.csv` (Japanese column names and factor levels; create it with `Rscript tests/make_testdata.R`) shows all six plots, including the ROC curve;
3. a regression tree can be built from `site/CART/data/iris.csv` (response `Sepal.Length`);
4. every download works (five PDFs, one PNG, and three CSV files encoded in CP932).

Known failure modes:

- Plots fail with `invalid 'width' argument`: the page was rendered with zero width (e.g. in a hidden tab). Reload it in a visible window.
- A package is not available for webR: the export warns about it. Check <https://repo.r-wasm.org/>.
- `system()` and other OS calls do not work in webR: branch on `R.version$os == "emscripten"`.

## Adding an app

1. Put `ui.R` and `server.R` (or `app.R`) in `apps/<Name>/`.
2. Run `Rscript build.R <Name>`.
3. Add the app to the list in `site/index.html` and run `Rscript build.R` again.
4. Check it locally, then commit and push.

## License

- Code written for this repository: MIT (see `LICENSE`).
- Example data, font and runtime (Shinylive, webR, R packages): see `THIRD-PARTY.md`.
