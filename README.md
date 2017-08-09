# Ensemble Scheduler

メンバーの重複がある複数のチームが、同時に作業する場合の、スケジューリングを支援するスクリプトです。

## Requirements

- Ruby (>= 2.0)
- bundler

## Installation

    git clone https://github.com/labocho/ensemble_scheduler.git
    cd ensemble_scheduler
    bundle
    bundle exec ./ensemble_scheduler.rb --help

## Data file

下記のような YAML を用意してください。

    teams:
      - name: チーム 1
        members:
          - メンバー 1
          - メンバー 2
          - メンバー 3
      - name: チーム 2
        members:
          - メンバー 2
          - メンバー 4
      - name: チーム 3
        members:
          - メンバー 4
          - メンバー 5


## Usage

出力は CSV です。文字コードは UTF-8、改行コードは LF ですが、UTF8 BOM つきなので Excel で直接開くことができます。

### teams

    $ bundle exec ./ensemble_scheduler.rb teams data.yml

|    member     | チーム 1 | チーム 2 | チーム 3 |
|---------------|----------|----------|----------|
|    メンバー 1 | v        |          |          |
|    メンバー 2 | v        | v        |          |
|    メンバー 3 | v        |          |          |
|    メンバー 4 |          | v        | v        |
|    メンバー 5 |          |          | v        |

各メンバーが所属するチームを一覧します。

上例では、メンバー4 は、チーム 2 と チーム 3 に所属していることがわかります。

### conflicts

    $ bundle exec ./ensemble_scheduler.rb teams data.yml

|    team1    | team2    | score | detail     |
|-------------|----------|-------|------------|
|    チーム 1 | チーム 2 | 1     | メンバー 2 |
|    チーム 1 | チーム 3 | 0     |            |
|    チーム 2 | チーム 1 | 1     | メンバー 2 |
|    チーム 2 | チーム 3 | 1     | メンバー 4 |
|    チーム 3 | チーム 1 | 0     |            |
|    チーム 3 | チーム 2 | 1     | メンバー 4 |

チーム間のメンバーの重複を一覧します。
上例では、チーム 1 とチーム 2 では メンバー 2 が重複していることがわかります。

### score

    $ bundle exec ./ensemble_scheduler.rb score data.yml 2 2

|    score | conflicts  | block1              | block2   |
|----------|------------|---------------------|----------|
|    -1    | メンバー 2 | チーム 1 / チーム 2 | チーム 3 |
|    0     |            | チーム 1 / チーム 3 | チーム 2 |
|    -1    | メンバー 4 | チーム 2 / チーム 3 | チーム 1 |


指定した数の作業スペース・時間帯で、同時に作業するチームの組み合わせを一覧します。

上例では チーム 1 と チーム 3 が同時に作業し、別の時間に チーム 2 が作業すると、メンバーが欠けることなく作業可能なことがわかります。
また、チーム 1 / チーム 2 が同時に作業し、別の時間に チーム 3 が作業する場合は、メンバー 2 が欠けるチームが 1 つ発生することがわかります。

