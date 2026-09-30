# fork-features

このリポジトリは `mizchi/actrun` のソフトフォーク（upstream のリリースに追従しつつ、独自のコミットを上に積む fork）である。
fork だけが持つ機能ごとに、その機能が効いているかを確かめる fixture をここに置く。

## fixture の構成

各ディレクトリは次を持つ。

- `feature.txt`: `id`（ディレクトリ名と同じ）、`commit`（その機能を入れた fork のコミットの件名）、`summary`（何を保証するか）
- `.github/workflows/check.yml`: 機能が効いていれば成功し、効いていなければ失敗するワークフロー
- `check.yml` が使う composite action などの補助ファイル
- `remote/<owner>/<repo>/`（任意）: `uses: <owner>/<repo>/...@v1` で取得させたいリポジトリの中身。スクリプトがそれぞれを `v1` タグ付きの git リポジトリにして、`ACTRUN_GITHUB_BASE_URL=file://...` で GitHub の代わりに取得させる

`scripts/fork_features_check.sh <actrun のコマンド>` は、各 fixture を一時ディレクトリにコピーして git リポジトリにし、
`check.yml` を実行して `<id>\t<pass|fail>` を出力する。

```sh
bash scripts/fork_features_check.sh _build/native/debug/build/cmd/actrun/actrun.exe
```

fork の CI（`ci.yml` の e2e ジョブ）では、fork 自身のビルドで全 fixture が `pass` することを確認している。

## `$/` の解決元

`uses: $/path` は「実行中のコミットのリポジトリ」を指す（`./path` は step 実行時点のワークスペースを指す）。
`actrun workflow run` は、ワークフローが `$/` を使っているとき、実行開始前のワークスペースを
`_build/actrun/self_repository/snap.*`（実行ごとに別。job の `container:` からも見える場所）にスナップショットし、`$/` のアクションはそこから読み込む。実行後にスナップショットは削除される。
ワークスペースが git リポジトリのルートなら `git ls-files -co --exclude-standard` のファイル（未コミットの変更を含み、ignore されたファイルは含まない）を、そうでなければ `_build` と `.git` 以外をコピーする。

- worktree / tmp モードでは、ワークスペースは対象コミットから作られるので、スナップショットはそのコミットの内容になる
- `--local` モードではワークスペース＝作業ツリーそのものなので、スナップショットは「実行開始時点の作業ツリー」（未コミットの変更を含む）になる
- `--dry-run` などの実行しない経路ではスナップショットを作らず、`$/` はワークスペースから解決する

## upstream のリリースへの追従

`upstream.txt` の `version` は、最後に確認した upstream のリリースを表す。

1. upstream が新しいリリースを出すと、Renovate（`renovate.json`）が `upstream.txt` を更新する PR を作る
2. その PR で `.github/workflows/upstream-feature-check.md`（GitHub Agentic Workflow）が動き、
   upstream のそのリリースと fork をビルドして全 fixture を両方で実行し、
   「upstream が対応済みで fork のコミットを外せる機能」「引き続き fork だけの機能」と、リリースを取り込んだときの衝突の見込みを PR にコメントする
3. コメントを見てリリースを取り込み（対応済みの fork コミットは外す）、PR をマージする

リリースを取り込むときは、次の 2 点もあわせて直す。

- `package.json` の `version` が衝突したら `<upstream の版>-fork.0`（例: upstream が `0.33.0` なら `0.33.0-fork.0`）にする。この PR には changeset を足さない。マージするとその版がそのまま npm に公開される（下の「npm への公開」を参照）
- `CHANGELOG.md` の先頭が衝突したら、upstream の新しい版の節と fork の節を両方残す（changesets は fork の節を upstream の節の上に書き足す）

## npm への公開

この fork は npm に [`@toiroakr/actrun`](https://www.npmjs.com/package/@toiroakr/actrun) として公開する。
版は `<upstream の版>-fork.<n>`（例: `0.32.0-fork.1`）で、[changesets](https://github.com/changesets/changesets) の pre モード（`.changeset/pre.json` の tag が `fork`）で付ける。

- fork の変更を入れる PR には `pnpm exec changeset` で changeset を足す（種類は patch でよい。pre モードでは patch / minor どちらでも `-fork.<n>` の `<n>` だけが 1 つ上がり、upstream の版の部分は変わらない）
- main に changeset が入ると、`.github/workflows/release-fork.yml` が「chore: release」という PR を作る。この PR は `package.json` の版を上げて `CHANGELOG.md` に追記する
- その PR をマージすると、`scripts/release_publish.sh` が npm に `latest` の dist-tag で公開し、`v<版>` の git タグと GitHub Release を作る。npm に同じ版があるときは何もしない
- npm への認証は Trusted Publishing（GitHub Actions の OIDC）で行い、npm の token は使わない

## 機能を追加したとき

fork に新しい機能を入れたら、ここに fixture を 1 つ足す。
fork のビルドで `pass`、変更前（upstream）のビルドで `fail` になることを確かめてからコミットする。

Agentic Workflow の Markdown を変更したら `gh aw compile upstream-feature-check` で `.lock.yml` を再生成してコミットする。
