# YAMLカバレッジ用の実行記録

`ACTRUN_COVERAGE_DIR` を設定すると、実行時のフィールド解決と条件判定をJSONで記録する。計測対象のstepには `env.ACTRUN_COVERAGE_STEP`、jobには `env.ACTRUN_COVERAGE_JOB` として、呼び出し側で一意の識別子を付ける。通常の実行では設定不要。

```yaml
jobs:
  example:
    env:
      ACTRUN_COVERAGE_JOB: job-example
    steps:
      - if: env.ENABLED == 'true'
        env:
          ACTRUN_COVERAGE_STEP: step-example
          MESSAGE: ${{ github.workflow }}
        run: printf '%s\n' "$MESSAGE"
```

出力ディレクトリは実行前に作成する。ファイルは同じ識別子・フィールド・判定結果ごとに上書きするため、複数回の実行で到達箇所を集約できる。独立した計測には新しいディレクトリを使う。ファイル名には記録内容のSHA-256を使うため、集計時はファイル名ではなくJSONの各フィールドを読む。

```json
{"source":"step-example","field":"if","outcome":true}
```

記録対象:

- step、composite呼び出し、jobの `if` の最終判定
- stepおよびcomposite呼び出しの `continue-on-error` の最終判定
- stepの `env.<変数名>` の解決
- run stepの `run`、`shell`、`working-directory` の解決

識別子・フィールド名・条件の真偽だけを保存する。解決した値、環境変数の値、スクリプト内容、secretの値は保存しない。

composite呼び出しの `if` は子stepの実行前に一度だけ評価する。falseの場合は `always()` を持つ子孫も実行せず、子孫の条件判定は記録しない。

この記録はフィールドへの到達を表し、expression内部の各演算子や短絡評価の網羅を表すものではない。`if` の結果には暗黙の `success()` も含まれる。`with`・outputsなどのすべてのYAMLフィールドに対応した仕組みではない。また、シェル内の行実行は別途計測する必要がある。

元のYAMLと識別子の対応、分母の列挙、外部actionの除外、集計は呼び出し側で行う。計画表示だけでは実行記録は作成しない。記録先への書き込みに失敗してもworkflowの動作は変えないため、呼び出し側で記録の生成を検証すること。
