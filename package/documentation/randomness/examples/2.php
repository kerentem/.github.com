<?php
	$win = 0;
	$cards = 5;
	$probability = 0.5;

	function generateScratchCard($n,$p) {
		$w = 0;
		for($i = 0; $i<$n; $i++) {
			$result = (mt_rand() / mt_getrandmax()); //
			if($result >= $p) {
				$w++;
			}
		}
		return $w;
	}
?>
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8" />
		<title>scratch.js - Example 4</title>
		<script type="text/javascript" src="assets/js/scratch.min.js"></script>
		<script>
			<?php
				$win = generateScratchCard($cards, $probability);
				echo "var win = ".$win."; ";
				echo "var cards = ".$cards."; ";
			?>
			var p = 0.5;
			var scratched = 0;

			function callback(d) {
				scratched++;
				if(scratched >= cards) {
					if(win > (cards/2)) {
						document.getElementById('result').innerHTML = 'Congratulations, you win!';
					} else {
						document.getElementById('result').innerHTML = 'You lose, but you can try again!';
					}
				}
			}

			//+ Function written by Jonas Raoni Soares Silva
			//@ http://jsfromhell.com/array/shuffle [v1.0]
			function shuffle(o){ //v1.0
				for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
				return o;
			};

			window.onload = function() {
				
				var container = document.getElementById('container');
				var cardsArray = [];
				for(var i=0, l=cards; i<l; i++) {
					if(i<win) {
						cardsArray[i] = true;
					} else {
						cardsArray[i] = false;
					}
				}
				shuffledArray = shuffle(cardsArray);
				for(var i=0; i<cards; i++) {
					var scratchCard = document.createElement('div');
					var backgroundImage;
					if(shuffledArray[i]) {
						backgroundImage = 'assets/images/win.png';
					} else {
						backgroundImage = 'assets/images/lose.png';
					}

					container.appendChild(scratchCard);
					createScratchCard({
						'container':scratchCard,
						'background':backgroundImage,
						'foreground':'assets/images/foreground.png',
						'percent':40,
						'coin':'assets/images/coin2.png',
						'thickness':18,
						'counter':'percent',
						'callback':'callback'
					});
				}

				
			};
		</script>
		<style>
			#container { margin: 50px auto; width: 900px; }
			#container div { display: inline-block; vertical-align: top; }
			#result { font-size: 15px; text-align: center; color: #514d4d; text-transform: uppercase; font-weight: bold; padding: 15px 0 15px; }
		</style>
	</head>
	<body>
		<div id="container"></div>
		<div id="result"></div>
	</body>
</html>