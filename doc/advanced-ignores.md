# Ignoring certain changes from the command line

`octocatalog-diff` provides a means to ignore certain changes in the displayed output. You may choose to ignore a change because you know it has no effect on the system. Or perhaps you are aware that the change is being made (perhaps in many different places) and you want to suppress it so other changes will not be lost in the noise.

## Built-in ignores

`octocatalog-diff` automatically ignores any changes to the following:

- Classes and class parameters. Classes themselves are structures to contain resources, but do not themselves trigger actions on agents. Resources in classes are reported on, but the actual classes themselves, and parameters associated with the classes, are not.
- Tags. Tags are useful for classification and collecting resources, but tags themselves do not trigger actions on agents. If you would like to see changes to tags, you can use `--no-ignore-tags`. Please note that tags are sorted alphabetically before comparison, so differences to the order of the tags will not ever show as a difference.
- Resource attributes: `before` and `require`. These attributes control ordering on the agent, but we have found that displaying them in the diff has little value because the target resources are not often seen. If you are looking to visualize your infrastructure, Puppet Enterprise [now has that feature](https://puppet.com/blog/visualize-your-infrastructure-models). Please note: `octocatalog-diff` does display changes to `subscribe` and `notify` parameters.

## Ignoring via the `--ignore` command line option

If you specify multiple `--ignore` options, they are OR'd. In other words, if a change matches *any* of the ignored conditions, it is ignored.

### Ignoring by type

If you wish to ignore all changes to a certain resource type, use this syntax. For example, if you wanted to ignore all changes to 'exec' you would use:

      --ignore 'Exec[*]'

Or to ignore changes to a custom defined type, you would use:

      --ignore 'Your::Custom::Type[*]'

The matching is case insensitive, so `--ignore Exec[*]` and `--ignore exec[*]` are equivalent.

### Ignoring by type and title

If you wish to ignore all changes to a certain resource identified by its type and title, use this syntax. For example, to ignore all changes to your `/etc/motd` file you would use:

      --ignore 'File[/etc/motd]'

You can use wildcards in the title. Wildcards can be placed at the beginning, in the middle, or at the end of the title. You can also use multiple wildcards. `*` is the only wildcard supported, and it matches 0 or more characters. For example:

      --ignore 'File[*]'             - Ignores all files
      --ignore 'File[/etc/foo/*]'    - Ignores all files in or under '/etc/foo'
      --ignore 'File[*/foo]'         - Ignores files named 'foo' anywhere in the file system
      --ignore 'File[/etc/*/foo]'    - Ignores files named 'foo' in subdirectories of '/etc/'
      --ignore 'File[/etc/*/foo/*]'  - Ignores all files under subdirectories named 'foo' under '/etc'

Note that unlike on a unix system, `*` here matches any character, including "dot files." Therefore `--ignore File[/home/joe/*]` *would* ignore changes made, for example, to `/home/joe/.bashrc`.

:warning: Do not put quotes of any kind in the ignore (e.g. `File['/etc/passwd']`) as these will be interpreted literally.

### Ignoring by attribute

If you wish to ignore all changes to a particular attribute regardless of the resource with which it is associated, use this syntax. For example, if you wanted to ignore all changes to an attribute called `i_dont_care_about_this` you would use:

      --ignore-attr 'i_dont_care_about_this'

That syntax will ignore a key `i_dont_care_about_this` *anywhere* it appears in the data structure -- top level key, last key, or something in between.

If you want more control over where in the data structure the key appears, you can use '::' to separate multiple layers. For example, if your resource looked like this:

      {
        "type": "File",
        "title": "/tmp/foo",
        "parameters": {
          "owner": "root",
          "i_dont_care_about_this": "foo bar"
        }
      }

You could use the following syntax to suppress `i_dont_care_about_this` only as it appears in the parameters hash using:

      --ignore-attr 'parameters::i_dont_care_about_this'

If you want to specify that you are starting from the top of the data structure, prepend `::` to the attribute. For example:

      --ignore-attr '::parameters::i_dont_care_about_this'

The difference between this syntax and the one appearing immediately before it is as follows. With the leading `::` it forces the attribute match to start at the top level of the data structure. Without the leading `::`, *any* place in the data structure where a key named `parameters` was a hash containing a key named `i_dont_care_about_this` would be matched. Typically there is not a deep level of nesting in Puppet catalogs so this distinction is minimal. However, multiple levels of nesting can occur when hashes are passed as parameters within Puppet manifests.

TIP: For most attributes you wish to ignore, you should start with `::parameters` which is the standard top-level data structure within each catalog resource. As such, the remaining examples in this section will use this syntax.

Functionally, `--ignore-attr 'FOO'` is equivalent to `--ignore '*[*]FOO'`, but that's less elegant. The prior example *could* be rewritten as:

      --ignore '*[*]::parameters::i_dont_care_about_this'

### Ignoring by type, title, and attribute

`octocatalog-diff` allows you to ignore attributes that belong only to a specified type, or type + title.

For example, maybe you want to ignore ownership changes to your `/tmp/foo` file. You could use the following syntax:

      --ignore 'File[/tmp/foo]::parameters::owner'

You can use wildcards `*` in the resource title as described previously. For example, to ignore owner changes for all files in the `/tmp` directory you could use:

      --ignore 'File[/tmp/*]::parameters::owner'

### Ignoring by type, title, and attribute with conditions

These functions allow you to ignore attributes, but only if the values of the attributes themselves or nature of the changes satisfy certain conditions.

#### Ignoring additions and removals but not changes

You can ignore resources that were added to the catalog. This syntax will *not* display an entry for any file in `/tmp` that was brand new in the new catalog. However, if the file resource existed in the old catalog and something changed, that's a change and not an addition, so it will display. For example:

      --ignore 'File[/tmp/*]+'

The above will suppress this change because it's strictly an addition:

      + File[/tmp/brand-new-file]

The above will NOT suppress this change because the resource existed before and changed:

~~~~~~~~
+ File[/tmp/my-file] =>
   parameters =>
     owner =>
       - root
       + new-owner
~~~~~~~~

Similarly, you can ignore resources that were entirely removed from the catalog.

      --ignore 'File[/tmp/*]-'

And, you can ignore resources that were either entirely removed or entirely added:

~~~~~~~~
--ignore 'File[/tmp/*]+-'
(or, equivalently)
--ignore 'File[/tmp/*]+' --ignore 'File[/tmp/*]-'
~~~~~~~~

#### Ignoring for a specific value of an attribute

You can ignore changes to an attribute when the value of the attribute matches a specific string or pattern.

When you use this syntax, the tool will ignore the change if the specified value applies to the attribute in *either* the old catalog or the new catalog. To ignore all changes to file owners, if the file owner was root before or the file owner is now root, you could use the `=>` matcher:

      --ignore 'File[/tmp/*]::parameters::owner=>root'

You can also use a regular expression. For example, to ignore changes if a file's content change includes "ice cream" you could use the `=~>` regular expression matcher:

      ---ignore 'File[/tmp/*]::parameters::content=~>ice cream'

#### Ignoring attributes that were added or removed

Similar to ignoring resources that were added or removed, you can also ignore attributes that were added or removed by prefixing the attribute name with a `+` or `-`.

To ignore any new parameters named `foo` (i.e., where no attribute named `foo` was defined in the old catalog, but it is defined in the new catalog), you would use:

      --ignore 'My::Custom::Resource[*]+::parameters::foo'

Similarly, to ignore the removal of the parameter named `foo` (i.e., where `foo` was defined in the old catalog, but is not defined in the new catalog), you would use:

      --ignore 'My::Custom::Resource[*]-::parameters::foo'

It is possible to combine this condition with the attribute value check defined above. For example, to ignore a new parameter `foo` with value `bar`:

      --ignore 'My::Custom::Resource[*]+::parameters::foo=>bar'

#### Ignoring attribute values but only in the new catalog or the old catalog

Commonly, you will wish to suppress changes if an attribute is a certain value in the new catalog (or perhaps, a certain value in the old catalog). Say for example that you want to ignore any files that are now owned by root, but you will want to know about files that were owned by root and are now owned by somebody else. `=>root` would match files that were owned by root in the old catalog too but changed to somebody else in the new catalog, so that is too broad.

The `=+>` operator performs a string match only in the new catalog, and `=->` performs a string match only in the new catalog. This will ignore any file resources under `/tmp` where the owner has changed, and the new owner is root:

      --ignore 'File[/tmp/*]::parameters::owner=+>root'

As a similar example, perhaps you have terminated a user joe, and need to reassign ownership of his files to someone else. You want to ignore any files that were previously owned by joe, but you do want to know about files that you've accidentally reassigned *to* joe (because you don't believe there should be any). To ignore files owned by joe in the old catalog, where the new owner is someone other than joe:

      --ignore 'File[/tmp/*]::parameters::owner=->joe'

If you need to use regular expressions, note that *changed lines* are preceded by `+` or `-` due to the `diff` implementation. More complicated, but equally functional, representations of the above commands are, respectively:

      --ignore 'File[/tmp/*]::parameters::owner=~>^\+root$'

      --ignore 'File[/tmp/*]::parameters::owner=~>^-joe$'

:warning: Be sure to escape your literal '+' in the regular expression!

Note that this syntax differs from `--ignore 'File[/tmp/*]+::...'` described in the prior section. The `+` or `-` between the title and the attribute indicates that the attribute must be brand new or completely removed; this will not ignore changes. Whereas using a `+` or `-` in the predicate of a string matcher will match changes between the catalogs.

If you want to ignore changes where the attribute value exactly matches certain value in the old catalog, and exactly matches a certain other value in the new catalog, this is possible using the encompassing regular expressions described in the next section. You cannot combine `=+>` and `=->` in the same ignore condition.

#### Ignoring attributes whose changes are encompassed by a regular expression

It is possible to ignore changes only if *all* changed lines are matched by a regular expression. This is useful to suppress expected changes to an attribute, while still surfacing unexpected changes.

As an example, consider that two catalogs defined the content of a file, which had this difference:

~~~~~~~~
File[/tmp/foo] =>
 parameters =>
   content =>
    @@ -1,4 +1,4 @@
     # This file is managed by Puppet. DO NOT EDIT.
    -This is the line in the old catalog that I do not care about
    +This is the line in the new catalog that I do not care about
     This line is very important
~~~~~~~~

Suppose that you do not care to see this change. You can use the `=&>` operator to specify *one* regular expression that must match *all* lines that are changed. (You do not need to worry about the `@@ -1,4 +1,4 @@` line, as that's an artifact of the `diff` process, and is not considered in the analysis.)

One implementation of ignoring the line in question could be:

      --ignore 'File[/tmp/foo]::parameters::content=&>^(-This is the line in the old catalog that I do not care about)|(\+This is the line in the new catalog that I do not care about)$'

If you aren't concerned about an edge case such as "This is the line in the new catalog that I do not care about" appearing in the old catalog, you could condense this to:

      --ignore 'File[/tmp/foo]::parameters::content=&>^[\-\+]This is the line in the (old|new) catalog that I do not care about$'

Consider now that the change to the file looked like this instead:

~~~~~~~~
File[/tmp/foo] =>
 parameters =>
   content =>
    @@ -1,4 +1,4 @@
     # This file is managed by Puppet. DO NOT EDIT.
    -This is the line in the old catalog that I do not care about
    +This is the line in the new catalog that I do not care about
    -This line is very important
~~~~~~~~

In this case, the very important line was removed from the catalog, and you want to know about this. Ignoring `File[/tmp/foo]::parameters::content` would have suppressed this (because all changes to that attribute are ignored). Also ignoring `File[/tmp/foo]::parameters::content=~>This is the line in the new catalog that I do not care about$` would have also suppressed this (because the regular expression was matched for *one* of the lines). However, the two examples with `=&>` in this section would *not* have suppressed this change, because it is no longer the case that *all* changes in the file matched the regular expression.

:warning: All lines are stripped of leading and trailing spaces before the regular expression match is tried. This stripping of whitespace is done *only* for this comparison stage, and does not affect the display of any results.

#### Ignoring attributes which have identical elements but in arbitrary order

You can ignore attributes where both the values in both the old and new catalogs are arrays and the arrays
contain identical elements but in arbitrary order. Basically, you can ignore a parameter where the values
have set equality.

To ignore any parameters named `foo` with values having set equality, you would use:

      --ignore 'My::Custom::Resource[*]::parameters::foo=s>='
