# octocatalog-diff change log

<table><thead>
<tr>
<th>Version</th>
<th>Date</th>
<th>Description / Changes</th>
</tr>
</thead><tbody>
<tr valign=top>
<td>0.99.0rc2</td>
<td>2017-01-23</td>
<td>
<ul>
<li><a href="https://github.com/github/octocatalog-diff/pull/70">#70</a> Missing `[]=` method in display code</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/77">#77</a> `FactOverride` -> `Override`</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/74">#74</a> Allow override of ENC parameters</li>
</ul>
</td>
</tr>

<tr valign=top>
<td>0.99.0rc1</td>
<td>2017-01-16</td>
<td>
This is a release candidate for `octocatalog-diff` version 1.0. Please report any problems to us as <a href="https://github.com/github/octocatalog-diff/issues/new">in a new issue</a>.

The previous release (0.6.1) is available at: https://github.com/github/octocatalog-diff/tree/0.6.1

<h4>New Features</h4>

The most significant change in version 1.0 is the addition of the <a href="./dev/api.md">V1 API</a>, which permits developers to build catalogs (<code>--catalog-only</code>) and compare/diff catalogs using octocatalog-diff. Under the hood, we've rearranged the code to support these APIs, which should also improve the reliability and allow faster development cycles.

<h4>Breaking Changes</h4>

The format of the output from <code>--output-format json</code> has changed. In version 0.x of the software, each difference was represented by an array. In version 1.x, each difference is represented by a hash with meaningful English keys. We have added an option <code>--output-format legacy_json</code> if anyone depends upon the output in the old format.
</td>
</tr>
<tr valign=top>
<td>0.6.1</td>
<td>2017-01-07</td>
<td>
<ul>
<li><a href="https://github.com/github/octocatalog-diff/pull/46">#46</a>: Add option to ignore whitespace in yaml file diff</li>
</ul>
</td>
</tr>
<tr valign=top>
<td>0.6.0</td>
<td>2017-01-04</td>
<td>
<ul>
<li><a href="https://github.com/github/octocatalog-diff/pull/45">#45</a>: Support for alternate environments in hiera configuration</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/43">#43</a>: Consider aliased resources in validation</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/39">#39</a>: Pass command line arguments to Puppet during catalog compilation</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/38">#38</a>: Preserve and select environments</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/37">#37</a>: Consistent sorting of equally weighted options</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/36">#36</a>: Validate before, notify, require, subscribe references</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/34">#34</a>: Allow bootstrap script to start with /</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/33">#33</a>: Double-escape facts passed to Puppet master</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/32">#32</a>: Rewrite hiera data directory for multiple backends</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/24">#24</a>: Support PuppetDB API v3</li>
</ul>
</td>
</tr>
<tr valign=top>
<td>0.5.6</td>
<td>2016-11-16</td>
<td>
<ul>
<li><a href="https://github.com/github/octocatalog-diff/pull/20">#20</a>: Use modulepath from environment.conf to inform lookup directories for <code>--compare-file-text</code> feature</li>
</ul>
</td>
</tr>
<tr valign=top>
<td>0.5.5</td>
<td>-</td>
<td>
Unreleased internal version
</td>
</tr>
<tr valign=top>
<td>0.5.4</td>
<td>2016-11-07</td>
<td>
<ul>
<li><a href="https://github.com/github/octocatalog-diff/pull/16">#16</a>: environment running <code>puppet --version</code></li>
<li><a href="https://github.com/github/octocatalog-diff/pull/5">#5</a>: bootstrap debugging</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/17">#17</a>: hiera simplification and <code>--hiera-path</code> option</li>
</ul>
</td>
</tr>
<tr valign=top>
<td>0.5.3</td>
<td>2016-10-31</td>
<td>
<ul>
<li><a href="https://github.com/github/octocatalog-diff/pull/10">#10</a>: facts terminus optimization</li>
</ul>
</td>
</tr>
<tr valign=top>
<td>0.5.2</td>
<td>-</td>
<td>Unreleased internal version</td>
</tr>
<tr valign=top>
<td>0.5.1</td>
<td>2016-10-20</td>
<td>Initial release</td>
</tr>
</tbody></table>
