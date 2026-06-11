<div align="center">

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPL License][license-shield]][license-url]

[![Readme in English](https://img.shields.io/badge/Readme-English-blue)](README.md)

<a href="https://mono.net.tr/">
  <img src="https://r2.mono.tr/logo/Mono-Logo.svg" width="340"/>
</a>

<h2>Redmine Auto Relate</h2>

A Redmine plugin that automatically links issues together when you mention them
with `#NNN` in an issue description or a note.

</div>

When you write something like *"see also #123"* in a note or description,
issue **#123** is automatically added to the current issue's **Related issues**
list — no manual linking step required.

## Features

- Scans **issue descriptions** on save and **journal notes** on creation.
- Extracts every `#NNN` mention and creates an `IssueRelation` (default type: `relates`).
- **Idempotent**: re-mentioning the same issue does not create a duplicate relation.
- **Safe**: skips non-existent issues, self-references, and issues the author cannot see.
- **Configurable**: relation type and per-source (description / notes) toggles via the
  Redmine admin UI.
- **Smart matching**: ignores `##NNN` (the textile note-link syntax), `word#NNN`,
  and `path/segment#NNN`.

## Requirements

- Redmine **5.0** or newer (developed and tested on Redmine 6.1.1, Rails 7.2, Ruby 3.3).

## Installation

```bash
cd /opt/redmine/plugins
git clone https://github.com/monobilisim/redmine-auto-relate.git redmine_auto_relate

cd /opt/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# Restart your application server, e.g.:
systemctl restart puma
```

> **Note:** the plugin directory **must** be named `redmine_auto_relate`
> (underscores), matching the plugin id Redmine expects.

## Configuration

Go to **Administration → Plugins → Redmine Auto Relate → Configure** and set:

| Setting | Description | Default |
|---|---|---|
| Relation type | Type of relation to create. Any value from `IssueRelation::TYPES` (`relates`, `blocks`, `duplicates`, `precedes`, …) | `relates` |
| Scan description | Parse `#NNN` mentions in issue descriptions on save | enabled |
| Scan notes | Parse `#NNN` mentions in journal notes on creation | enabled |

## How It Works

The plugin patches two core models:

- `Issue` — an `after_save` callback runs whenever the description changes.
- `Journal` — an `after_create_commit` callback runs whenever a new note is added
  to an `Issue`.

Both call into a shared `RedmineAutoRelate.link_all` helper that:

1. Extracts every issue id matched by the regex `(?<![#\w\/])#(\d+)\b`.
2. For each id, looks up the target issue.
3. Skips it if the target does not exist, is the same as the source issue,
   or is not visible to the acting user.
4. Skips it if a relation in either direction already exists.
5. Creates a new `IssueRelation` of the configured type.

### What matches

| Input | Matches? | Why |
|---|---|---|
| `see #123` | yes | standard mention |
| `Fixes #42 and #43` | yes | multiple mentions |
| `##123` | no | textile note-link syntax |
| `commit/abc#123` | no | preceded by a path segment |
| `word#123` | no | preceded by a word character |

## Caveats

- The plugin reacts to **future** events only. Issues and journals created
  **before** the plugin was installed are not back-filled.
- Old descriptions are not re-scanned on unrelated updates — the description
  must actually change for the description-scan to trigger.

## Manual Verification

You can verify the plugin is loaded with:

```bash
cd /opt/redmine
bundle exec rails runner -e production '
  puts "Issue patched:   #{Issue.ancestors.include?(RedmineAutoRelate::IssuePatch)}"
  puts "Journal patched: #{Journal.ancestors.include?(RedmineAutoRelate::JournalPatch)}"
  puts "Parser sample:   #{RedmineAutoRelate.extract_issue_ids(\"see #12 and #34 but not ##99\").inspect}"
'
```

Expected output:

```
Issue patched:   true
Journal patched: true
Parser sample:   [12, 34]
```

## Uninstall

```bash
rm -rf /opt/redmine/plugins/redmine_auto_relate
systemctl restart puma
```

No database migrations are applied, so there is nothing to roll back.

## License

Released under the **GNU General Public License v3.0**. See [`LICENSE`](LICENSE)
for the full text.

## Author

Ali Erdem Cerrah — [Mono Bilişim](https://github.com/monobilisim)

[contributors-shield]: https://img.shields.io/github/contributors/monobilisim/redmine-auto-relate.svg?style=for-the-badge
[contributors-url]: https://github.com/monobilisim/redmine-auto-relate/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/monobilisim/redmine-auto-relate.svg?style=for-the-badge
[forks-url]: https://github.com/monobilisim/redmine-auto-relate/network/members
[stars-shield]: https://img.shields.io/github/stars/monobilisim/redmine-auto-relate.svg?style=for-the-badge
[stars-url]: https://github.com/monobilisim/redmine-auto-relate/stargazers
[issues-shield]: https://img.shields.io/github/issues/monobilisim/redmine-auto-relate.svg?style=for-the-badge
[issues-url]: https://github.com/monobilisim/redmine-auto-relate/issues
[license-shield]: https://img.shields.io/github/license/monobilisim/redmine-auto-relate.svg?style=for-the-badge
[license-url]: https://github.com/monobilisim/redmine-auto-relate/blob/main/LICENSE
