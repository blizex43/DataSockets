import { DataOptions } from "./DataControls/DataOptions";
import { Players } from "@rbxts/services";
import { resolveStructure } from "./DataControls/DataStructure";

import { deserializeData, serializeData } from "./DataControls/DataFormat";
import { isRuleBroken, ruleBreak } from "./DataControls/DataRules";
import { New as Signal, SignalType } from "./@shared/Signal";
import { Error, Warn } from "./Utils/Natives/Functions";
import Trove from "./@shared/Trove/Trove";
import QuickNetwork, { DataNetwork, DataObject } from "./@shared/QuickNetwork";
interface NetworkSequence {
	importNetwork(): DataNetwork;
	runFallbacks(createdNetwork: DataNetwork): void;
	onDataChanged: SignalType;
}
interface PlayerDataSequence {
	onPlayerDataConstructed: SignalType;
	listenForPlayers(): void;
	loadPlayer(player: Player, playerTrove: Trove): QuickNetwork.DataObject | undefined;
	handlePlayer(player: Player): void;
	removePlayer(player: Player): void;
	formatPlayerKey(player: Player): string;
}

interface DataSocketSequence {
	onWipeRequested: SignalType;
	onDataRequested: SignalType;
	requestDataAsync(player: Player): DataObject | void;
	requestWipeAsync(player: Player): boolean;
}

abstract class Network implements NetworkSequence {
	public onDataChanged: SignalType = Signal();

	importNetwork(): DataNetwork {
		const dataNetwork = QuickNetwork.GetDataNetwork(
			DataOptions.Name,
			resolveStructure(DataOptions.Structure, DataOptions.StructureExtern),
		);
		this.runFallbacks(dataNetwork);
		return dataNetwork;
	}
	runFallbacks(createdNetwork: DataNetwork): void {
		createdNetwork.DataCorruptionLoadSignal.Connect(() => "loadBackup");
		createdNetwork.DataErrorLoadSignal.Connect(() => "loadBackup");
	}
}
abstract class PlayerData extends Network implements PlayerDataSequence {
	protected dataNetwork: DataNetwork = this.importNetwork();
	protected playerTroves: Record<number, Trove> = {};
	public onPlayerDataConstructed: SignalType = Signal();

	listenForPlayers(): void {
		Players.PlayerAdded.Connect((player: Player) => this.handlePlayer(player));
		Players.PlayerRemoving.Connect((player: Player) => this.removePlayer(player));
		Players.GetPlayers().forEach((player: Player) => this.handlePlayer(player));
	}

	formatPlayerKey(player: Player): string {
		return `${DataOptions.Prefix}${player.UserId}${DataOptions.Suffix}`;
	}

	loadPlayer(player: Player, playerTrove: Trove = new Trove()): QuickNetwork.DataObject | undefined {
		if (this.playerTroves[player.UserId] === undefined) this.playerTroves[player.UserId] = playerTrove;
		return playerTrove
			.AddPromise(
				new Promise((resolve: Callback) => {
					resolve(this.dataNetwork.LoadDataAsync(this.formatPlayerKey(player)));
				}),
			)
			.andThen((maybeData: QuickNetwork.DataObject | undefined) => {
				if (maybeData === undefined) {
					throw new Error("Player Data is Undefined");
				}
				return maybeData as QuickNetwork.DataObject;
			})
			.catch(() => {
				const [serverResponse, playerResponse] = ruleBreak(player, 2);
				new Warn(serverResponse);
				player.Kick(playerResponse);
				return undefined;
			})
			.expect();
	}

	handlePlayer(player: Player) {
		const ruleBroken = isRuleBroken(player, {});
		if (ruleBroken) {
			const [serverResponse, playerResponse] = ruleBreak(player, ruleBroken);
			new Warn(serverResponse);
			player.Kick(playerResponse);
		}
		const playerTrove = new Trove();
		this.playerTroves[player.UserId] = playerTrove;
		const playerData = this.loadPlayer(player, playerTrove) as QuickNetwork.DataObject;
		if (!playerData) {
			playerTrove.Clean();
			return;
		}
		playerTrove.Add(() => playerData.ListenToUpdate.Connect((...args) => this.onDataChanged.Fire(player, ...args)));
		playerData.Reconcile();
		deserializeData(playerData);
		this.onPlayerDataConstructed.Fire(player, playerData);
	}

	removePlayer(player: Player): void {
		const playerData = this.dataNetwork.GetCachedData(this.formatPlayerKey(player));
		const playerTrove = this.playerTroves[player.UserId];
		if (!playerData) return;
		serializeData(playerData);
		print(playerData);
		playerData.Clear();
		if (playerTrove) playerTrove.Clean();
		delete this.playerTroves[player.UserId];
	}
}

class DataSockets extends PlayerData implements DataSocketSequence {
	onDataRequested: SignalType<unknown[]> = Signal();
	onWipeRequested: SignalType<unknown[]> = Signal();
	constructor() {
		super();
	}

	public requestDataAsync(player: Player): DataObject | void {
		const onlinePlayerData = this.dataNetwork.GetCachedData(this.formatPlayerKey(player));
		if (onlinePlayerData) return onlinePlayerData;
		const playerData = this.loadPlayer(player);
		if (playerData) return playerData;
	}

	public requestWipeAsync(player: Player): boolean {
		const playerData = this.requestDataAsync(player);
		if (!playerData) return false;
		playerData.Wipe(true);
		return true;
	}
}
export = new DataSockets();
