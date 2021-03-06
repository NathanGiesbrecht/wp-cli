Feature: Scaffold plugin unit tests

  Scenario: Scaffold plugin tests
    Given a WP install
    When I run `wp plugin path`
    Then save STDOUT as {PLUGIN_DIR}

    When I run `wp scaffold plugin hello-world --skip-tests`
    Then STDOUT should not be empty
    And the {PLUGIN_DIR}/hello-world/.editorconfig file should exist
    And the {PLUGIN_DIR}/hello-world/hello-world.php file should exist
    And the {PLUGIN_DIR}/hello-world/readme.txt file should exist
    And the {PLUGIN_DIR}/hello-world/tests directory should not exist

    When I run `wp scaffold plugin-tests hello-world`
    Then STDOUT should not be empty
    And the {PLUGIN_DIR}/hello-world/tests directory should contain:
      """
      bootstrap.php
      test-sample.php
      """
    And the {PLUGIN_DIR}/hello-world/tests/bootstrap.php file should contain:
      """
      require dirname( dirname( __FILE__ ) ) . '/hello-world.php';
      """
    And the {PLUGIN_DIR}/hello-world/tests/bootstrap.php file should contain:
      """
      * @package Hello_World
      """
    And the {PLUGIN_DIR}/hello-world/tests/test-sample.php file should contain:
      """
      * @package Hello_World
      """
    And the {PLUGIN_DIR}/hello-world/bin directory should contain:
      """
      install-wp-tests.sh
      """
    And the {PLUGIN_DIR}/hello-world/phpunit.xml.dist file should exist
    And the {PLUGIN_DIR}/hello-world/phpcs.ruleset.xml file should exist
    And the {PLUGIN_DIR}/hello-world/circle.yml file should not exist
    And the {PLUGIN_DIR}/hello-world/.gitlab-ci.yml file should not exist
    And the {PLUGIN_DIR}/hello-world/.travis.yml file should contain:
      """
      script:
        - |
          if [[ ! -z "$WP_VERSION" ]] ; then
            phpunit
            WP_MULTISITE=1 phpunit
          fi
        - |
          if [[ "$WP_TRAVISCI" == "phpcs" ]] ; then
            phpcs --standard=phpcs.ruleset.xml $(find . -name '*.php')
          fi
      """
    And the {PLUGIN_DIR}/hello-world/.travis.yml file should contain:
      """
      matrix:
        include:
          - php: 7.1
            env: WP_VERSION=latest
          - php: 7.0
            env: WP_VERSION=latest
          - php: 5.6
            env: WP_VERSION=4.4
          - php: 5.6
            env: WP_VERSION=latest
          - php: 5.6
            env: WP_VERSION=trunk
          - php: 5.6
            env: WP_TRAVISCI=phpcs
          - php: 5.3
            env: WP_VERSION=latest
      """

    When I run `wp eval "if ( is_executable( '{PLUGIN_DIR}/hello-world/bin/install-wp-tests.sh' ) ) { echo 'executable'; } else { exit( 1 ); }"`
    Then STDOUT should be:
      """
      executable
      """

  Scenario: Scaffold plugin tests with Circle as the provider, part one
    Given a WP install
    And I run `wp scaffold plugin hello-world --ci=circle`

    When I run `wp plugin path hello-world --dir`
    Then save STDOUT as {PLUGIN_DIR}
    And the {PLUGIN_DIR}/.travis.yml file should not exist
    And the {PLUGIN_DIR}/circle.yml file should contain:
      """
      version: 5.6.22
      """

  Scenario: Scaffold plugin tests with Circle as the provider, part two
    Given a WP install
    And I run `wp scaffold plugin hello-world --skip-tests`

    When I run `wp plugin path hello-world --dir`
    Then save STDOUT as {PLUGIN_DIR}

    When I run `wp scaffold plugin-tests hello-world --ci=circle`
    Then STDOUT should not be empty
    And the {PLUGIN_DIR}/.travis.yml file should not exist
    And the {PLUGIN_DIR}/circle.yml file should contain:
      """
      version: 5.6.22
      """
    And the {PLUGIN_DIR}/circle.yml file should contain:
      """
          - |
            rm -rf $WP_TESTS_DIR $WP_CORE_DIR
            bash bin/install-wp-tests.sh wordpress_test ubuntu '' 127.0.0.1 4.4
            phpunit
            WP_MULTISITE=1 phpunit
          - |
            rm -rf $WP_TESTS_DIR $WP_CORE_DIR
            bash bin/install-wp-tests.sh wordpress_test ubuntu '' 127.0.0.1 latest
            phpunit
            WP_MULTISITE=1 phpunit
          - |
            rm -rf $WP_TESTS_DIR $WP_CORE_DIR
            bash bin/install-wp-tests.sh wordpress_test ubuntu '' 127.0.0.1 trunk
            phpunit
            WP_MULTISITE=1 phpunit
      """

  Scenario: Scaffold plugin tests with Gitlab as the provider
    Given a WP install
    And I run `wp scaffold plugin hello-world --skip-tests`

    When I run `wp plugin path hello-world --dir`
    Then save STDOUT as {PLUGIN_DIR}

    When I run `wp scaffold plugin-tests hello-world --ci=gitlab`
    Then STDOUT should not be empty
    And the {PLUGIN_DIR}/.travis.yml file should not exist
    And the {PLUGIN_DIR}/.gitlab-ci.yml file should contain:
      """
      MYSQL_DATABASE
      """

  Scenario: Scaffold plugin tests with invalid slug
    Given a WP install

    When I try `wp scaffold plugin-tests .`
    Then STDERR should contain:
      """
      Error: Invalid plugin slug specified.
      """

    When I try `wp scaffold plugin-tests ../`
    Then STDERR should contain:
      """
      Error: Invalid plugin slug specified.
      """
