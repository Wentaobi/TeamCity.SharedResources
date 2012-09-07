package jetbrains.buildServer.sharedResources.server;

import com.intellij.openapi.diagnostic.Logger;
import jetbrains.buildServer.serverSide.*;
import jetbrains.buildServer.serverSide.buildDistribution.*;
import jetbrains.buildServer.sharedResources.SharedResourcesPluginConstants;
import org.jetbrains.annotations.NotNull;

import java.util.*;

/**
 * Class {SharedResourcesBuildAgentsFilter}
 *
 * Implements filtering of agents based on locks
 *
 * @author Oleg Rybak
 */
public class SharedResourcesBuildAgentsFilter implements StartingBuildAgentsFilter {

  private static final Logger LOG = Logger.getInstance(SharedResourcesBuildAgentsFilter.class.getName());

  private final static WaitReason WAIT_FOR_LOCK = new SimpleWaitReason("Build is waiting for lock");

  private final RunningBuildsManager myRunningBuildsManager;

  public SharedResourcesBuildAgentsFilter(RunningBuildsManager runningBuildsManager) {
    myRunningBuildsManager = runningBuildsManager;
  }

  @NotNull
  public AgentsFilterResult filterAgents(@NotNull AgentsFilterContext context) {
    LOG.debug("(SharedResourcesBuildAgentsFilter) start");

    final AgentsFilterResult result = new AgentsFilterResult();
    final QueuedBuildInfo queuedBuild = context.getStartingBuild();
    final BuildPromotionEx promo = (BuildPromotionEx)queuedBuild.getBuildPromotionInfo();
    final BuildTypeEx buildType = promo.getBuildType();
    final Set<String> locks = new HashSet<String>();

    if (buildType != null) {
      Collection<SBuildFeatureDescriptor> buildFeatures = buildType.getBuildFeatures();
      // gather all locks
      for (SBuildFeatureDescriptor descriptor: buildFeatures) {
        if (SharedResourcesPluginConstants.FEATURE_TYPE.equals(descriptor.getType())) {
          locks.add(descriptor.getParameters().get(SharedResourcesPluginConstants.RESOURCE_PARAM_KEY));
        }
      }
    }

    if (!locks.isEmpty())  {
      // if we have some locks, check them against other running builds
      boolean locksAvailable = true;
      List<SRunningBuild> runningBuilds = myRunningBuildsManager.getRunningBuilds();
      for (SRunningBuild build: runningBuilds) {
        SBuildType type = build.getBuildType();
        if (type != null) {
          Collection<SBuildFeatureDescriptor> buildFeatures = type.getBuildFeatures();
          for (SBuildFeatureDescriptor descriptor: buildFeatures) {
            if (SharedResourcesPluginConstants.FEATURE_TYPE.equals(descriptor.getType())) {
              if (locks.contains(descriptor.getParameters().get(SharedResourcesPluginConstants.RESOURCE_PARAM_KEY))) {
                locksAvailable = false;
                break;
              }
            }
          }
        }
      }
      if (!locksAvailable) {
        result.setFilteredConnectedAgents(Collections.<SBuildAgent>emptyList());
        result.setWaitReason(WAIT_FOR_LOCK);
        LOG.debug("(SharedResourcesBuildAgentsFilter) putting build on wait");
      }
    }
    LOG.debug("(SharedResourcesBuildAgentsFilter) finish");
    return result;
  }
}