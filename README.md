#  Update Drupal 10.5 -> Drupal 11.2

## Audit
1. Add audit.sh to your repo root
2. Run `sh audit.sh` to exectute the script
3. The script will output a list of:
    - services from the `.platform/services.yaml` file
    - php version from the `.platform.app.yaml` file
    - a list of custom modules contained in `web/modules/custom`
    - composer dependencies not included in the boilerplate
    - patches in the composer file
4. The results will also be written to a `project_summary.md` file in the project root.

## Update Drupal 10.x -> Drupal 11.2

[repo here](https://github.com/ubc-web-services/d11upgrade)

### Prepare DDEV

1.  Add ddev to the project `ddev config` (most defaults are fine for projects without additional services like solr), use `drupal11` recipe
2.  Run `composer install` to pull in current dependencies
3.  Add the scripts in the `ddev-web-commands` directory to `.ddev/commands/web/`
4.  Start the site with `ddev start`
5.  Import the db with `ddev import-db < [databasename]`
6.  Flush caches `ddev drush cr`
7.  Run script with `ddev d11prepare`

### Script operations

The script will first ask whether the site is based on a VPR, Science, APSC or other boilerplate. It then attempts to make the following updates

#### Modules updated

-   Drush
-   Webform
-   Editor Advanced Link (only if in composer file, pinned to 2.3.1)
-   File Delete
-   CKEditor5 Fullscreen
-   Formtips (needs to straddle versions: \^1.11||\^2.0)
-   Gin (needs to straddle versions: \^4.1||\^5.0)
-   Gin Toolbar (needs to straddle versions: \^2.1||\^3.0)
-   Image Widget Crop
-   Linkit (pinned to 7.0.10)
-   Linkit Media Library
-   UBC Portfolio modules (does not include CWL or custom modules)
-   UBC Recipes

#### Additional updates

-   Add and install the Upgrade Status module (if needed)
-   Update the core version requirement to VPR and Science portfolio child themes
-   Prompt you to add the core version requirement if you’re using a custom theme
-   alter the recipe location to the root directory
-   alter the .gitignore to remove /web/recipes/ and add /recipes/
-   delete the old recipes stored in /web/recipes from the local project

#### Cleanup

-  The following files will be deleted:
   -  .lando
   -  landoquickstart.sh
   -  LICENSE
   -  project_summary.md (if present)
   -  simplessamlphp directory (conditional - only if cwl modules are not in composer)
-  If cypress is the only node package in the root package.json:
   -  /cypress (directory and contents)
   -  cypress.json
   -  package.json
   -  package-lock.json
-  Make sure to commit any changes (ie. ddev, .gitignore, composer) once you are ready to proceed

### Next Steps

1.  Review and resolve the issues on the Upgrade Status page

-   /admin/reports/upgrade-status
-   Note that formtips will show as having an _Incompatible_ local version, but that can be disregarded since we are straddling required versions. The updated version will be pulled in when core is updated.

2.  Backup work

-   Run database updates to ensure the latest changes are in place.
    `ddev drush updb` OR `lando drush updb`
-   Export database in case you want to roll back.
    `ddev export-db --file=db.sql.gz` OR `ddev snapshot`

3.  Run Update: also see [Official Docs](https://www.drupal.org/docs/upgrading-drupal/upgrading-from-drupal-8-or-later/how-to-upgrade-from-drupal-10-to-drupal-11)

-   Update permissions.

```
chmod 777 web/sites/default
chmod 666 web/sites/default/*settings.php
chmod 666 web/sites/default/*services.yml

```

-   Change core without updating.

```
composer require 'drupal/core-recommended:^11' \
'drupal/core-composer-scaffold:^11' \
'drupal/core-project-message:^11' --no-update

```

-   Perform the update dry-run
    `composer update --dry-run`
-   If no errors, perform the update
    `composer update`
-   Run database updates again.
    `ddev drush updb`
-   Reinstate permissions (optional on local)

```
chmod 777 web/sites/default
chmod 666 web/sites/default/*settings.php
chmod 666 web/sites/default/*services.yml

```

4. Update DDEV recipe
-  `ddev config` and choose Drupal11 recipe

5.  Commit all changes

6. Update database
- `ddev drush updb`

7. Disable Upgrade Status module
- `ddev drush pmu upgrade_status `

8. Export config
- `ddev drush cex -y`

9. Commit all changes