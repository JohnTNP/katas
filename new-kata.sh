#!/usr/bin/env sh

set -eu

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

validate_name() {
    trimmed_name=$(trim "$1")

    [ -n "$trimmed_name" ] || fail 'Kata name is required.'

    case "$trimmed_name" in
        *[!A-Za-z0-9\ -]*) fail 'Kata name may contain only letters, numbers, spaces, and hyphens.' ;;
    esac

    printf '%s' "$trimmed_name"
}

get_slug() {
    slug=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[ -][ -]*/-/g; s/^-//; s/-$//')
    [ -n "$slug" ] || fail 'Kata name could not be converted into a folder name.'
    printf '%s' "$slug"
}

get_pascal_case_name() {
    pascal_case_name=$(printf '%s' "$1" | awk 'BEGIN { FS = "[ -]+" } { for (i = 1; i <= NF; i++) { if ($i == "") { continue } printf "%s%s", toupper(substr($i, 1, 1)), tolower(substr($i, 2)) } }')

    [ -n "$pascal_case_name" ] || fail 'Kata name could not be converted into a C# identifier.'

    case "$pascal_case_name" in
        [A-Za-z][A-Za-z0-9]*) ;;
        *) fail 'Kata name must produce a C# identifier that starts with a letter.' ;;
    esac

    printf '%s' "$pascal_case_name"
}

copy_template_directory() {
    source_dir=$1
    destination_dir=$2

    find "$source_dir" -mindepth 1 | while IFS= read -r path; do
        relative_path=${path#"$source_dir"/}

        case "/$relative_path/" in
            */bin/*|*/obj/*) continue ;;
        esac

        target_path=$destination_dir/$relative_path

        if [ -d "$path" ]; then
            mkdir -p "$target_path"
            continue
        fi

        mkdir -p "$(dirname "$target_path")"
        cp "$path" "$target_path"
    done
}

rewrite_solution_file() {
    solution_path=$1
    pascal_case_name=$2

    cat > "$solution_path" <<EOF
<Solution>
  <Project Path="$pascal_case_name.Tests/$pascal_case_name.Tests.csproj" />
  <Project Path="$pascal_case_name/$pascal_case_name.csproj" />
</Solution>
EOF
}

rewrite_test_project_file() {
    project_path=$1
    pascal_case_name=$2

    cat > "$project_path" <<EOF
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="coverlet.collector" Version="6.0.4" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="../$pascal_case_name/$pascal_case_name.csproj" />
  </ItemGroup>

</Project>
EOF
}

rewrite_class_file() {
    class_file_path=$1
    namespace_name=$2

    cat > "$class_file_path" <<EOF
namespace $namespace_name;

public class Class1
{

}
EOF
}

rewrite_unit_test_file() {
    test_file_path=$1
    namespace_name=$2

    cat > "$test_file_path" <<EOF
namespace $namespace_name;

public class UnitTest1
{
    [Fact]
    public void Test1()
    {

    }
}
EOF
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
template_root=$script_dir/templates/csharp-kata
katas_root=$script_dir/katas

name=${1-}

if [ -z "${name}" ]; then
    printf 'Enter kata name: '
    IFS= read -r name || true
fi

if [ "$#" -ge 2 ]; then
    description=$2
else
    printf 'Enter kata description (optional): '
    IFS= read -r description || true
fi

validated_name=$(validate_name "$name")
slug=$(get_slug "$validated_name")
pascal_case_name=$(get_pascal_case_name "$validated_name")
destination_root=$katas_root/$slug

[ -d "$template_root" ] || fail "Template folder not found: $template_root"
[ -d "$katas_root" ] || fail "Katas folder not found: $katas_root"
[ ! -e "$destination_root" ] || fail "Destination already exists: $destination_root"

mkdir -p "$destination_root"
copy_template_directory "$template_root" "$destination_root"

mv "$destination_root/csharp-kata.slnx" "$destination_root/$pascal_case_name.slnx"
mv "$destination_root/Kata" "$destination_root/$pascal_case_name"
mv "$destination_root/Kata.Tests" "$destination_root/$pascal_case_name.Tests"
mv "$destination_root/$pascal_case_name/Kata.csproj" "$destination_root/$pascal_case_name/$pascal_case_name.csproj"
mv "$destination_root/$pascal_case_name.Tests/Kata.Tests.csproj" "$destination_root/$pascal_case_name.Tests/$pascal_case_name.Tests.csproj"

rewrite_solution_file "$destination_root/$pascal_case_name.slnx" "$pascal_case_name"
rewrite_test_project_file "$destination_root/$pascal_case_name.Tests/$pascal_case_name.Tests.csproj" "$pascal_case_name"
rewrite_class_file "$destination_root/$pascal_case_name/Class1.cs" "$pascal_case_name"
rewrite_unit_test_file "$destination_root/$pascal_case_name.Tests/UnitTest1.cs" "$pascal_case_name.Tests"

if [ -n "$(trim "$description")" ]; then
    printf '%s\n' "$(trim "$description")" > "$destination_root/README.md"
fi

printf 'Created kata at %s\n' "$destination_root"