
# Geting version from tag
version=`git describe --abbrev=0 --tags`

# Change version in podspec
sed -i ".bak" "s/s.version      = .*/s.version      = '"$version"'/" GQLFetcher.podspec

# Adding repo if needs
if pod repo list | grep -e "cropio-specs"; then
  echo 'Repo already exist'
else
  pod repo add cropio-specs git@github.com:cropio/cocoapods-specs.git
fi

# Push library to repo
pod repo push cropio-specs GQLFetcher.podspec --verbose --allow-warnings --sources=https://github.com/cropio/cocoapods-specs.git,https://cdn.cocoapods.org/

# Back to primary
git checkout GQLFetcher.podspec
rm -f GQLFetcher.podspec.bak
