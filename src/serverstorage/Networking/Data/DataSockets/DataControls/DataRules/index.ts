import TagAliases from "../../Utils/TagAliases";
import RuleCodes from "./RuleCodes";

export function isRuleBroken(
	player: Player,
	playerData: Record<string, unknown> | unknown,
): keyof typeof RuleCodes | void {
	// Ask
	if (player.AccountAge < 7) {
		return 2;
	} else if (playerData === undefined) {
		return 1;
	} else if (game.Workspace.HasTag(TagAliases.ServerShutdown)) {
		return 3;
	}
}

export function ruleBreak(player: Player, ruleCode: keyof typeof RuleCodes): [string, string] {
	return [RuleCodes[ruleCode].ServerOutput.format(player.Name), RuleCodes[ruleCode].PlayerOutput.format(player.Name)];
}
