#  Update Drupal 10.5 -> Drupal 11.2

1. Spin up local instance in lando with all files (private and public) on a clean branch
2. Add the `update.sh` script to the project root: [repo here](https://github.com/ubc-web-services/d11upgrade)
3. Run Update script in root. This will complete the following updates:

	- Drush
	- Webform (+adds patch - not needed once https://www.drupal.org/project/webform/issues/3526888 is in a release)
	- File Delete
	- Formtips (needs to straddle versions:  \^1.11||\^2.0)
	- Gin (needs to straddle versions:  \^4.1||\^5.0)
	- Gin Toolbar (needs to straddle versions:  \^2.1||\^3.0)
	- Image Widget Crop
	- Linkit
	- Linkit Media Library
	- UBC Portfolio modules (does not include CWL or custom modules)

	Additionally, it will:

	- Add and install the Upgrade Status module (if needed)
	- Update the core version requirement to VPR and Science portfolio child themes
	- Prompt you to add the core version requirement if you're using a custom theme

	```
	sh update.sh
	```

4. Review and resolve the issues on the Upgrade Status page
	- /admin/reports/upgrade-status
	- Note that formtips will show as having an *Incompatible* local version, but that can be disregarded since we are straddling required versions. The updated version will be pulled in when core is updated.

5. Backup work
	- Run database updates to ensure the latest changes are in place.
	`lando drush updb`
	- Export database in case you want to roll back.
	`lando db-export`
6. Run Update: also see [Official Docs](https://www.drupal.org/docs/upgrading-drupal/upgrading-from-drupal-8-or-later/how-to-upgrade-from-drupal-10-to-drupal-11)
	- Update permissions.
		```
		chmod 777 web/sites/default
		chmod 666 web/sites/default/*settings.php
		chmod 666 web/sites/default/*services.yml
		```
	- Change core without updating.
		```
		composer require 'drupal/core-recommended:^11' \
		                 'drupal/core-composer-scaffold:^11' \
		                 'drupal/core-project-message:^11' --no-update
		```
	- Perform the update dry-run
	`composer update --dry-run`
	- If no errors, perform the update
	`composer update`
	- Run database updates again.
	`lando drush updb`
	- Reinstate permissions (optional on local)
		```
		chmod 777 web/sites/default
		chmod 666 web/sites/default/*settings.php
		chmod 666 web/sites/default/*services.yml
		```
7. Commit all changes
