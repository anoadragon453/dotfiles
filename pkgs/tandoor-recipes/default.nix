{ callPackage
, nixosTests
, python3
, fetchFromGitHub
, lib
}:
let
  python = python3.override {
    packageOverrides = self: super: {
      django = super.django_4;

      # Tests are incompatible with Django 4
      django-js-reverse = super.django-js-reverse.overridePythonAttrs (_: {
        doCheck = false;
      });
    };
  };

  # TODO: Upstream this to nixpkgs.
  crispy-bootstrap4 = python.pkgs.pythonPackages.buildPythonPackage rec {
    pname = "crispy-bootstrap4";
    version = "2023.1";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "django-crispy-forms";
      repo = "crispy-bootstrap4";
      rev = "refs/tags/${version}";
      hash = "sha256-4p6dlyQYZGyfBntTuzCjikL8ZG/4xDnTiQ1rCVt0Hbk=";
    };

    propagatedBuildInputs = [
      python.pkgs.pythonPackages.django
      python.pkgs.pythonPackages.django-crispy-forms
      python.pkgs.pythonPackages.setuptools
    ];

    # FIXME: RuntimeError: Model class source.crispy_forms.tests.forms.CrispyTestModel doesn't declare an explicit app_label and isn't in an application in INSTALLED_APPS.
    #doCheck = false;

    nativeCheckInputs = [
      python.pkgs.pythonPackages.pytest-django
      python.pkgs.pythonPackages.pytestCheckHook
    ];

    pythonImportsCheck = [ "crispy_bootstrap4" ];

    meta = with lib; {
      description = "Bootstrap 4 template pack for django-crispy-forms";
      homepage = "https://github.com/django-crispy-forms/crispy-bootstrap4";
      license = licenses.mit;
      maintainers = with maintainers; [ anoadragon453 ];
    };
  };

  common = callPackage ./common.nix { };

  frontend = callPackage ./frontend.nix { };
in
python.pkgs.pythonPackages.buildPythonPackage rec {
  pname = "tandoor-recipes";

  inherit (common) version src;

  format = "other";

  patches = [
    # Allow setting MEDIA_ROOT through environment variable
    ./media-root.patch
  ];

  propagatedBuildInputs = with python.pkgs; [
    beautifulsoup4
    bleach
    bleach-allowlist
    boto3
    crispy-bootstrap4
    cryptography
    django
    django-allauth
    django-annoying
    django-auth-ldap
    django-autocomplete-light
    django-cleanup
    django-cors-headers
    django-crispy-forms
    django-hcaptcha
    django-js-reverse
    django-oauth-toolkit
    django-prometheus
    django-scopes
    django-storages
    django-tables2
    django-webpack-loader
    django-treebeard
    djangorestframework
    drf-writable-nested
    gunicorn
    icalendar
    jinja2
    lxml
    markdown
    microdata
    pillow
    psycopg2
    pyppeteer
    python-dotenv
    pytube
    pyyaml
    recipe-scrapers
    requests
    six
    uritemplate
    validators
    webdavclient3
    whitenoise
  ];

  configurePhase = ''
    runHook preConfigure

    ln -sf ${frontend}/ cookbook/static/vue
    cp ${frontend}/webpack-stats.json vue/

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    # Disable debug logging
    export DEBUG=0
    # Avoid dependency on django debug toolbar
    export DEBUG_TOOLBAR=0

    # See https://github.com/TandoorRecipes/recipes/issues/2043
    mkdir cookbook/static/themes/maps/
    touch cookbook/static/themes/maps/style.min.css.map
    touch cookbook/static/themes/bootstrap.min.css.map
    touch cookbook/static/css/bootstrap-vue.min.css.map

    ${python.pythonForBuild.interpreter} manage.py collectstatic_js_reverse
    ${python.pythonForBuild.interpreter} manage.py collectstatic

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r . $out/lib/tandoor-recipes
    chmod +x $out/lib/tandoor-recipes/manage.py
    makeWrapper $out/lib/tandoor-recipes/manage.py $out/bin/tandoor-recipes \
      --prefix PYTHONPATH : "$PYTHONPATH"

    # usually copied during frontend build (see vue.config.js)
    cp vue/src/sw.js $out/lib/tandoor-recipes/cookbook/templates/

    runHook postInstall
  '';

  nativeCheckInputs = with python.pkgs; [
    pytestCheckHook
    pytest-django
    pytest-factoryboy
  ];

  passthru = {
    inherit frontend python;

    updateScript = ./update.sh;

    tests = {
      inherit (nixosTests) tandoor-recipes;
    };
  };

  meta = common.meta // {
    description = ''
      Application for managing recipes, planning meals, building shopping lists
      and much much more!
    '';
  };
}