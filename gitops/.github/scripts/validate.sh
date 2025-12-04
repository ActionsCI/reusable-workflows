set -euo pipefail

error_found=0
for service_dir in service/*; do
  if [ -d "${service_dir}" ]; then
    # Check for service.yaml in each service directory
    if [ ! -f "${service_dir}/service.yaml" ]; then
      echo "❌ Missing service.yaml in ${service_dir}"
      error_found=1
    fi

    # For each env directory under service/<service>, check values.yaml
    checked_envs=()
    for env_dir in ${service_dir}/*; do
      if [ -d "${env_dir}" ]; then
        if [ ! -f "${env_dir}/values.yaml" ]; then
          echo "❌ Missing values.yaml in ${env_dir}"
          error_found=1
        fi
        checked_envs+=($(basename "${env_dir}"))
      fi
    done

    echo "Finished ${service_dir} ${checked_envs[@]}"
  fi
done

if [ $error_found -eq 1 ]; then
  echo "Errors were found. Please fix them and try again."
  exit 1
else
  echo "✅ No issues found!"
fi
