{{/*
Expand the name of the chart.
*/}}
{{- define "wordpress-chart.name" -}}
{{- default .Chart.Name .Values.client.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "wordpress-chart.fullname" -}}
{{- printf "%s-%s" .Values.client.name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Chart name and version as used by the chart label.
*/}}
{{- define "wordpress-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end }}
