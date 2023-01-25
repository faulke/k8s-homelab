{{- define "library.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "helpers.fullname" . }}
  labels:
    {{- include "helpers.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      protocol: TCP
  {{- with .Values.externalIps }}
  externalIps:
    {{- toYaml . | nindent 4 }}
  {{- end}}
  selector:
    {{- include "helpers.selectorLabels" . | nindent 4 }}
{{- end }}