// Sample Usage
import { DataObject } from "../../serverstorage/Networking/Data/DataSockets/@shared/QuickNetwork";
import DataSockets from "../../serverstorage/Networking/Data/DataSockets";
import { console } from "../../serverstorage/Networking/Data/DataSockets/Utils/Natives/Console";
import TagAliases from "../../serverstorage/Networking/Data/DataSockets/Utils/TagAliases";

// Listeners
DataSockets.onPlayerDataConstructed.Connect((...args: unknown[]) => {
	const [player, playerData] = args as [Player, DataObject];
	player.AddTag(TagAliases.DataLoaded);
	console.log(`${player.Name} has successfully loaded into the game!`);
	const loginAmount: number = playerData["loginAmount"] as number;
	playerData.Set("loginAmount", loginAmount + 1);
});

DataSockets.onDataChanged.Connect((...args: unknown[]) => {
	const [player, key, value] = args as [Player, string, unknown];
	console.log(`Data of player [${player.Name}] has changed!
		\n[key] => ${key}
		\n[value] => ${value}]`);
});
DataSockets.listenForPlayers();
print(DataSockets);
