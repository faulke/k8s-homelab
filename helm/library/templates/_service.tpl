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
      targetPort: {{ .Values.service.port }}
      protocol: TCP
  selector:
    {{- include "helpers.selectorLabels" . | nindent 4 }}
{{- end }}