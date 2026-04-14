package de.tavernup.camunda;

import org.camunda.bpm.engine.impl.bpmn.behavior.ExternalTaskActivityBehavior;
import org.camunda.bpm.engine.impl.bpmn.parser.AbstractBpmnParseListener;
import org.camunda.bpm.engine.impl.cfg.AbstractProcessEnginePlugin;
import org.camunda.bpm.engine.impl.cfg.ProcessEngineConfigurationImpl;
import org.camunda.bpm.engine.impl.pvm.process.ActivityImpl;
import org.camunda.bpm.engine.impl.pvm.process.ScopeImpl;
import org.camunda.bpm.engine.impl.task.TaskDefinition;
import org.camunda.bpm.engine.impl.util.xml.Element;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class WebhookNotificationPlugin extends AbstractProcessEnginePlugin {

    private static final Logger LOG = Logger.getLogger(WebhookNotificationPlugin.class.getName());

    @Override
    public void preInit(ProcessEngineConfigurationImpl config) {
        LOG.info("[TavernUp] Registering WebhookNotificationPlugin");
        List<org.camunda.bpm.engine.impl.bpmn.parser.BpmnParseListener> listeners =
            config.getCustomPreBPMNParseListeners();
        if (listeners == null) {
            listeners = new ArrayList<>();
            config.setCustomPreBPMNParseListeners(listeners);
        }
        listeners.add(new WebhookBpmnParseListener());
    }

    static class WebhookBpmnParseListener extends AbstractBpmnParseListener {

        @Override
        public void parseUserTask(Element userTaskElement, ScopeImpl scope, ActivityImpl activity) {
            try {
                // ActivityImpl erbt von ActivityBehavior-Containern — TaskDefinition
                // ist über getProperty("taskDefinition") erreichbar
                Object taskDef = activity.getProperty("taskDefinition");
                if (taskDef instanceof TaskDefinition) {
                    ((TaskDefinition) taskDef).addTaskListener(
                        org.camunda.bpm.engine.delegate.TaskListener.EVENTNAME_CREATE,
                        new TaskNotificationListener());
                }
            } catch (Exception e) {
                LOG.log(Level.WARNING, "[TavernUp] Could not attach TaskListener", e);
            }
        }

        @Override
        public void parseServiceTask(Element serviceTaskElement, ScopeImpl scope, ActivityImpl activity) {
            if (activity.getActivityBehavior() instanceof ExternalTaskActivityBehavior) {
                activity.addListener(
                    org.camunda.bpm.engine.delegate.ExecutionListener.EVENTNAME_START,
                    new ExecutionNotificationListener());
            }
        }
    }
}