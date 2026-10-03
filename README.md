# webR Shiny Apps

R Shiny apps that run entirely in the web browser with [Shinylive](https://posit-dev.github.io/r-shinylive/) / [webR](https://docs.r-wasm.org/webr/latest/), hosted on GitHub Pages.
Shinylive / webR により、ブラウザだけで動く R Shiny アプリを GitHub Pages で公開しています。
サーバーを使わないため、アップロードしたデータは利用者のパソコンから外に出ません。

<https://ksatohds.github.io/webR/>

| App | URL | Source |
|---|---|---|
| CART | <https://ksatohds.github.io/webR/CART/> | `apps/CART/` |

## 構成

| Path | 内容 |
|---|---|
| `apps/<app>/` | アプリのソース（`ui.R`, `server.R` と、アプリに同梱するファイル） |
| `site/` | `docs/` にそのままコピーするファイル（一覧ページ `index.html`、サンプルデータ） |
| `data-raw/` | サンプルデータの作成スクリプトと出典の文献情報 |
| `tests/` | 動作確認用データの作成スクリプト |
| `build.R` | 全アプリを `docs/` に書き出す |
| `docs/` | 公開物（GitHub Pages: main ブランチ `/docs`）。**手で編集しない** |

`docs/shinylive/` の webR 本体と R パッケージは全アプリで共有します。

## ビルド

R と CRAN の shinylive パッケージが必要です。

```bash
Rscript build.R          # 全アプリ
Rscript build.R CART     # CART だけ
```

アプリが使うパッケージは書き出し時に自動で検出され、WebAssembly 版が `docs/shinylive/webr/packages/` に同梱されます。
手元とWebAssembly版でバージョンが違うと警告が出ますが、書き出しは完了します。

## ローカルでの確認

`docs/` は HTTP で配信する必要があります（`file://` では動きません）。本番と同じ `/webR/` のパスで配信する例:

```bash
Rscript -e "httpuv::runServer('127.0.0.1', 7655, list(call = function(req) list(status = 404L, headers = list(), body = ''), staticPaths = list('/webR' = httpuv::staticPath('docs', indexhtml = TRUE))))"
```

<http://localhost:7655/webR/CART/> を開きます。

確認項目（ビルドし直したとき）:

1. ブラウザのコンソールに、パッケージ読み込みのエラーがないこと
2. `tests/data/birthwt_jp.csv`（日本語の列名・水準、`Rscript tests/make_testdata.R` で作成）で分類木を作り、6つの図と ROC 曲線が出ること
3. `site/CART/data/iris.csv` で回帰木（応答 `Sepal.Length`）が作れること
4. ダウンロードがすべて動くこと（PDF 5種、PNG、CSV 3種は CP932）

想定される失敗:

- 図が `invalid 'width' argument` になる → 表示幅が0（非表示のタブで開いている）。見える状態で再読み込みする
- webR にないパッケージを使っている → 書き出し時に警告が出る。<https://repo.r-wasm.org/> で確認する
- `system()` などの OS 呼び出し → webR では使えない（`R.version$os == "emscripten"` で分岐する）

## アプリの追加

1. `apps/<Name>/` に `ui.R` と `server.R`（または `app.R`）を置く
2. `Rscript build.R <Name>`
3. `site/index.html` の一覧に追記して、もう一度 `Rscript build.R`
4. ローカルで確認してから commit / push

## ライセンス

- 本リポジトリ用に書いたコード: MIT（`LICENSE`）
- サンプルデータ、フォント、実行環境（Shinylive / webR / R パッケージ）: `THIRD-PARTY.md`
