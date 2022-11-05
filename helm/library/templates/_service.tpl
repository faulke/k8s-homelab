{{- define "library.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "test.fullname" . }}
  labels:
    {{- include "test.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "test.selectorLabels" . | nindent 4 }}
{{- end }}