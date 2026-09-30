# fork-features

このリポジトリは `mizchi/actrun` のソフトフォーク（upstream のリリースに追従しつつ、独自のコミットを上に積む fork）である。
fork だけが持つ機能ごとに、その機能が効いているかを確かめる fixture をここに置く。

## fixture の構成

各ディレクトリは次を持つ。

- `feature.txt`: `id`（ディレクトリ名と同じ）、`commit`（その機能を入れた fork のコミットの件名）、`summary`（何を保証するか）
- `.github/workflows/check.yml`: 機能が効いていれば成功し、効いていなければ失敗するワークフロー
- `check.yml` が使う composite action などの補助ファイル

`scripts/fork_features_check.sh <actrun のコマンド>` は、各 fixture を一時ディレクトリにコピーして git リポジトリにし、
`check.yml` を実行して `<id>\t<pass|fail>` を出力する。

```sh
bash scripts/fork_features_check.sh _build/native/debug/build/cmd/actrun/actrun.exe
```

fork の CI（`ci.yml` の e2e ジョブ）では、fork 自身のビルドで全 fixture が `pass` することを確認している。

## `$/` の解決元

`uses: $/path` は「実行中のコミットのリポジトリ」を指す（`./path` は step 実行時点のワークスペースを指す）。
`actrun workflow run` は、ワークフローが `$/` を使っているとき、実行開始前のワークスペース（`_build` と `.git` を除く）を
`_build/actrun/self_repository/` にスナップショットし、`$/` のアクションはそこから読み込む。実行後にスナップショットは削除される。

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

## 機能を追加したとき

fork に新しい機能を入れたら、ここに fixture を 1 つ足す。
fork のビルドで `pass`、変更前（upstream）のビルドで `fail` になることを確かめてからコミットする。

Agentic Workflow の Markdown を変更したら `gh aw compile upstream-feature-check` で `.lock.yml` を再生成してコミットする。
