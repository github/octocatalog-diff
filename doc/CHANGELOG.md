# octocatalog-diff change log

<table><thead>
<tr>
<th>Version</th>
<th>Date</th>
<th>Description / Changes</th>
</tr>
</thead><tbody>

<tr valign=top>
<td>1.5.3</td>
<td>2018-03-05</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/176">#176</a>: (Enhancement) Normalize file resource titles in reference checks</li>
</td>
</tr>

<tr valign=top>
<td>1.5.2</td>
<td>2017-12-19</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/169">#169</a>: (Enhancement) Puppet Enterprise RBAC token to authenticate to PuppetDB</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/170">#170</a>: (Enhancement) Filter to treat an object the same as a single array containing that object</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/165">#165</a>: (Bug Fix) Override of fact file via CLI now has precedence over value set in configuration file</li>
</td>
</tr>

<tr valign=top>
<td>1.5.1</td>
<td>2017-11-16</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/159">#159</a>: (Enhancement) Add support for puppetdb behind basic auth</li>
</td>
</tr>

<tr valign=top>
<td>1.5.0</td>
<td>2017-10-18</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/151">#151</a>: (Enhancement) Support text differences in files where `source` is an array</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/153">#153</a>: (Enhancement) Support for hiera 5</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/152">#152</a>: (Internal) Better temporary directory handling</li>
</td>
</tr>
<tr valign=top>
<td>1.4.1</td>
<td>2017-10-02</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/149">#149</a>: (Internal) Set ports on PuppetDB URLs without altering constants</li>
</td>
</tr>
<tr valign=top>
<td>1.4.0</td>
<td>2017-08-03</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/135">#135</a>: (Enhancement) Puppet 5 compatibility</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/140">#140</a>: (Internal) Prefix tmpdirs with ocd-</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/138">#138</a>: (Internal) Refactor catalog class with proper inheritance</li>
</td>
</tr>
<tr valign=top>
<td>1.3.0</td>
<td>2017-06-09</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/121">#121</a>: (Enhancement) Allow different fact files for the "from" and "to" catalogs</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/129">#129</a>: (Enhancement) Allow YAML facts in "facter -y" format</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/126">#126</a>: (Enhancement) Allow saving of catalogs when catalog diffing</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/122">#122</a>: (Bug) Handle File resources with no parameters</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/125">#125</a>: (Bug) Fix error when parameters with integer values are added</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/131">#131</a>: (Bug) Do not use override fact file for both catalogs when only `--to-fact-file` is specified</li>
</td>
</tr>
<tr valign=top>
<td>1.2.0</td>
<td>2017-05-18</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/112">#112</a>: Split arguments added for ENC</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/113">#113</a>: (Enhancement) Override facts and ENC parameters using regular expressions</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/103">#111</a>: Simplify parallel processing to solve some intermittent failures</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/110">#110</a>: Ruby 2.4 compatibility</li>
</td>
</tr>
<tr valign=top>
<td>1.1.0</td>
<td>2017-05-08</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/108">#108</a>: (Bug) Support hiera.yaml backend declared as a string instead of array</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/105">#105</a>: (Bug) Remove legacy exclusion of tags</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/103">#103</a>: (Enhancement) Identify where the broken reference was declared</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/98">#98</a>: (Enhancement) Separate scripts and commands and make override-able</li>
</td>
</tr>
<tr valign=top>
<td>1.0.4</td>
<td>2017-03-17</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/94">#94</a>: Make Puppet version check respect env vars</li>
</td>
</tr>
<tr valign=top>
<td>1.0.3</td>
<td>2017-03-15</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/86">#86</a>: Ability to use `--environment` without `--preserve-environments`</li>
</td>
</tr>
<tr valign=top>
<td>1.0.2</td>
<td>2017-03-08</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/91">#91</a>: `--no-truncate-details` option</li>
</td>
</tr>
<tr valign=top>
<td>1.0.1</td>
<td>2017-02-14</td>
<td>
<li><a href="https://github.com/github/octocatalog-diff/pull/84">#84</a>: Add JSON equivalence filter</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/83">#83</a>: Retries for Puppet Master retrieval</li>
<li><a href="https://github.com/github/octocatalog-diff/pull/82">#82</a>: Command line option for Puppet Master timeout</li>
</td>
</tr>
<tr valign=top>
<td>1.0.0</td>
<td>2017-02-06</td>
<td>
This is the first release of the 1.0 series. For more information please see <a href="./versions/v1.md">What's new in octocatalog-diff 1.0</a>.
<br>
<br>
The most significant change in version 1.0 is the addition of the <a href="./dev/api.md">V1 API</a>, which permits developers to build catalogs (<code>--catalog-only</code>) and compare/diff catalogs using octocatalog-diff. Under the hood, we've rearranged the code to support these APIs, which should improve the reliability and allow faster development cycles.

<h4>Breaking Changes</h4>

The format of the output from <code>--output-format json</code> has changed. In version 0.x of the software, each difference was represented by an array. In version 1.x, each difference is represented by a hash with meaningful English keys. We have added an option <code>--output-format legacy_json</code> for anyone who may depend on the old format.
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
