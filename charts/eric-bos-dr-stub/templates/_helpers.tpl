{{/*
Any image path (DR-D1121-067)
*/}}
{{- define "eric-bos-dr-stub.imagePath" }}
    {{- $imageId := index . "imageId" -}}
    {{- $values := index . "values" -}}
    {{- $files := index . "files" -}}
    {{- $productInfo := fromYaml ($files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := index $productInfo "images" $imageId "registry" -}}
    {{- $repoPath := index $productInfo "images" $imageId "repoPath" -}}
    {{- $name := index $productInfo "images" $imageId "name" -}}
    {{- $tag :=  index $productInfo "images" $imageId "tag" -}}
    {{- if $values.global -}}
        {{- if $values.global.registry -}}
            {{- $registryUrl = default $registryUrl $values.global.registry.url -}}
        {{- end -}}
        {{- if not (kindIs "invalid" $values.global.registry.repoPath) -}}
            {{- $repoPath = $values.global.registry.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $values.imageCredentials -}}
        {{- if $values.imageCredentials.registry -}}
            {{- $registryUrl = default $registryUrl $values.imageCredentials.registry.url -}}
        {{- end -}}
        {{- if not (kindIs "invalid" $values.imageCredentials.repoPath) -}}
            {{- $repoPath = $values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- $image := index $values.imageCredentials $imageId -}}
        {{- if $image -}}
            {{- if $image.registry -}}
                {{- $registryUrl = default $registryUrl $image.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" $image.repoPath) -}}
                {{- $repoPath = $image.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-bos-dr-stub.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-bos-dr-stub.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create release name used for cluster role.
*/}}
{{- define "eric-bos-dr-stub.release.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Merge kubernetes-io-info, user-defined labels, and app and chart labels into a single set
of metadata labels.
*/}}
{{- define "eric-bos-dr-stub.labels" -}}
  {{- $kubernetesIoInfo := include "eric-bos-dr-stub.kubernetes-io-info" . | fromYaml -}}
  {{- $config := include "eric-bos-dr-stub.config-labels" . | fromYaml -}}
  {{- include "eric-bos-dr-stub.mergeLabels" (dict "location" .Template.Name "sources" (list $kubernetesIoInfo $config)) | trim }}
{{- end -}}

{{/*
Create Ericsson product app.kubernetes.io info
*/}}
{{- define "eric-bos-dr-stub.kubernetes-io-info" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Create user-defined labels
*/}}
{{ define "eric-bos-dr-stub.config-labels" }}
  {{- $global := (.Values.global).labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-bos-dr-stub.mergeLabels" (dict "location" .Template.Name "sources" (list $global $service)) }}
{{- end }}

{{/*
Merge eric-product-info, user-defined annotations, and Prometheus annotations into a single set
of metadata annotations.
*/}}
{{- define "eric-bos-dr-stub.annotations" -}}
  {{- $productInfo := include "eric-bos-dr-stub.product-info" . | fromYaml -}}
  {{- $config := include "eric-bos-dr-stub.config-annotations" . | fromYaml -}}
  {{- include "eric-bos-dr-stub.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $config)) | trim }}
{{- end -}}

{{/*
The name of the cluster role used during openshift deployments.
This helper is provided to allow use of the new global.security.privilegedPolicyClusterRoleName if set, otherwise
use the previous naming convention of <release_name>-allowed-use-privileged-policy for backwards compatibility.
*/}}
{{- define "eric-bos-dr-stub.privileged.cluster.role.name" -}}
  {{- if hasKey (.Values.global.security) "privilegedPolicyClusterRoleName" -}}
    {{ .Values.global.security.privilegedPolicyClusterRoleName }}
  {{- else -}}
    {{ template "eric-bos-dr-stub.release.name" . }}-allowed-use-privileged-policy
  {{- end -}}
{{- end -}}

{{- /*
Wrapper functions to set the contexts
*/ -}}
{{- define "eric-bos-dr-stub.mergeAnnotations" -}}
  {{- include "eric-bos-dr-stub.aggregatedMerge" (dict "context" "annotations" "location" .location "sources" .sources) }}
{{- end -}}
{{- define "eric-bos-dr-stub.mergeLabels" -}}
  {{- include "eric-bos-dr-stub.aggregatedMerge" (dict "context" "labels" "location" .location "sources" .sources) }}
{{- end -}}

{{/*
Create Ericsson Product Info
*/}}
{{- define "eric-bos-dr-stub.product-info" -}}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end}}

{{/*
Create user-defined annotations
*/}}
{{ define "eric-bos-dr-stub.config-annotations" }}
  {{- $global := (.Values.global).annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-bos-dr-stub.mergeAnnotations" (dict "location" .Template.Name "sources" (list $global $service)) }}
{{- end }}

{{- /*
Generic function for merging annotations and labels (version: 1.0.1)
{
    context: string
    sources: [[sourceData: {key => value}]]
}
This generic merge function is added to improve user experience
and help ADP services comply with the following design rules:
  - DR-D1121-060 (global labels and annotations)
  - DR-D1121-065 (annotations can be attached by application
                  developers, or by deployment engineers)
  - DR-D1121-068 (labels can be attached by application
                  developers, or by deployment engineers)
  - DR-D1121-160 (strings used as parameter value shall always
                  be quoted)
Installation or template generation of the Helm chart fails when:
  - same key is listed multiple times with different values
  - when the input is not string
IMPORTANT: This function is distributed between services verbatim.
Fixes and updates to this function will require services to reapply
this function to their codebase. Until usage of library charts is
supported in ADP, we will keep the function hardcoded here.
*/ -}}
{{- define "eric-bos-dr-stub.aggregatedMerge" -}}
  {{- $merged := dict -}}
  {{- $context := .context -}}
  {{- $location := .location -}}
  {{- range $sourceData := .sources -}}
    {{- range $key, $value := $sourceData -}}
      {{- /* FAIL: when the input is not string. */ -}}
      {{- if not (kindIs "string" $value) -}}
        {{- $problem := printf "Failed to merge keys for \"%s\" in \"%s\": invalid type" $context $location -}}
        {{- $details := printf "in \"%s\": \"%s\"." $key $value -}}
        {{- $reason := printf "The merge function only accepts strings as input." -}}
        {{- $solution := "To proceed, please pass the value as a string and try again." -}}
        {{- printf "%s %s %s %s" $problem $details $reason $solution | fail -}}
      {{- end -}}
      {{- if hasKey $merged $key -}}
        {{- $mergedValue := index $merged $key -}}
        {{- /* FAIL: when there are different values for a key. */ -}}
        {{- if ne $mergedValue $value -}}
          {{- $problem := printf "Failed to merge keys for \"%s\" in \"%s\": key duplication in" $context $location -}}
          {{- $details := printf "\"%s\": (\"%s\", \"%s\")." $key $mergedValue $value -}}
          {{- $reason := printf "The same key cannot have different values." -}}
          {{- $solution := "To proceed, please resolve the conflict and try again." -}}
          {{- printf "%s %s %s %s" $problem $details $reason $solution | fail -}}
        {{- end -}}
      {{- end -}}
      {{- $_ := set $merged $key $value -}}
    {{- end -}}
  {{- end -}}
{{- /*
Strings used as parameter value shall always be quoted. (DR-D1121-160)
The below is a workaround to toYaml, which removes the quotes.
Instead we loop over and quote each value.
*/ -}}
{{- range $key, $value := $merged }}
{{ $key }}: {{ $value | quote }}
{{- end -}}
{{- end -}}


{{/*
POD Antiaffinity type (soft/hard)
*/}}
{{- define "eric-bos-dr-stub.pod-antiaffinity-type" -}}
{{- $podantiaffinity := "soft" }}
{{- if .Values.affinity -}}
  {{- $podantiaffinity = .Values.affinity.podAntiAffinity }}
{{- end -}}
{{- if eq $podantiaffinity "hard" }}
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app.kubernetes.io/name
        operator: In
        values:
        - {{ template "eric-bos-dr-stub.name" . }}
    topologyKey: "kubernetes.io/hostname"
{{- else if eq $podantiaffinity "soft" -}}
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app.kubernetes.io/name
          operator: In
          values:
          - {{ template "eric-bos-dr-stub.name" .}}
      topologyKey: "kubernetes.io/hostname"
{{- end }}
{{- end }}

{{/*
This function takes (dict "Values" .Values "resourceName" "i.e: eric-bos-dr-stub") as parameter
And render the resource attributes (requests and limits)
* Values to access .Values
* resourceName to help access the specific resource from .Values.resources
*/}}
{{- define "eric-bos-dr-stub.resourcesHelper" -}}
requests:
{{- if index .Values.resources .resourceName "requests" "memory" }}
  memory: {{ index .Values.resources .resourceName "requests" "memory" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "requests" "cpu"}}
  cpu: {{ index .Values.resources .resourceName "requests" "cpu" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "requests" "ephemeral-storage"}}
  ephemeral-storage: {{ index .Values.resources .resourceName "requests" "ephemeral-storage" | quote}}
{{- end }}
limits:
{{- if index .Values.resources .resourceName "limits" "memory" }}
  memory: {{ index .Values.resources .resourceName "limits" "memory" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "limits" "cpu"}}
  cpu: {{ index .Values.resources .resourceName "limits" "cpu" | quote}}
{{- end }}
{{- if index .Values.resources .resourceName "limits" "ephemeral-storage"}}
  ephemeral-storage: {{ index .Values.resources .resourceName "limits" "ephemeral-storage" | quote}}
{{- end }}
{{- end -}}

{{/*
Enable Node Selector functionality
*/}}
{{- define "eric-bos-dr-stub.nodeSelector" -}}
{{- if .Values.global.nodeSelector }}
nodeSelector:
  {{ toYaml .Values.global.nodeSelector | trim }}
{{- else if .Values.nodeSelector }}
nodeSelector:
  {{ toYaml .Values.nodeSelector | trim }}
{{- end }}
{{- end -}}