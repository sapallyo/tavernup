package de.tavernup.camunda;

import org.camunda.bpm.engine.delegate.DelegateTask;
import org.camunda.bpm.engine.delegate.TaskListener;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class TaskNotificationListener implements TaskListener {

    private static final Logger LOG = Logger.getLogger(TaskNotificationListener.class.getName());

    @Override
    public void notify(DelegateTask task) {
        String webhookUrl = System.getenv().getOrDefault(
            "TAVERNUP_WEBHOOK_URL",
            "http://tavernup_server:8080/webhook/task-created");
        try {
            sendPost(webhookUrl, buildPayload(task));
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Webhook failed for task " + task.getId(), e);
        }
    }

    private String buildPayload(DelegateTask task) {
        StringBuilder vars = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Object> e : task.getVariables().entrySet()) {
            if (!first) vars.append(",");
            vars.append("\"").append(esc(e.getKey())).append("\":");
            Object v = e.getValue();
            if (v == null) vars.append("null");
            else if (v instanceof Number || v instanceof Boolean) vars.append(v);
            else vars.append("\"").append(esc(v.toString())).append("\"");
            first = false;
        }
        vars.append("}");
        return "{\"taskType\":\"userTask\","
            + "\"taskId\":\"" + esc(task.getId()) + "\","
            + "\"taskName\":\"" + esc(s(task.getName())) + "\","
            + "\"processInstanceId\":\"" + esc(task.getProcessInstanceId()) + "\","
            + "\"assignee\":\"" + esc(s(task.getAssignee())) + "\","
            + "\"variables\":" + vars + "}";
    }

    private void sendPost(String url, String payload) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
        c.setRequestMethod("POST");
        c.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        c.setConnectTimeout(3000);
        c.setReadTimeout(5000);
        c.setDoOutput(true);
        try (OutputStream os = c.getOutputStream()) {
            os.write(payload.getBytes(StandardCharsets.UTF_8));
        }
        int status = c.getResponseCode();
        if (status < 200 || status >= 300)
            LOG.warning("Webhook HTTP " + status);
        c.disconnect();
    }

    private String s(String v) { return v != null ? v : ""; }
    private String esc(String v) {
        if (v == null) return "";
        return v.replace("\\","\\\\").replace("\"","\\\"")
                .replace("\n","\\n").replace("\r","\\r").replace("\t","\\t");
    }
}