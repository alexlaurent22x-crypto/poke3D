# Optional: render real installed Windows French TTS to WAV before opening Unity.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voice = $synth.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -like 'fr-*' } | Select-Object -First 1
if (-not $voice) { throw 'Aucune voix française System.Speech installée. Installez une voix française Windows compatible ou ajoutez vos enregistrements dans Assets/POKS/Resources/Audio/Voice.' }
$synth.SelectVoice($voice.VoiceInfo.Name)
$synth.Rate = -1
$destination = Join-Path $PSScriptRoot '../Assets/POKS/Resources/Audio/Voice'
New-Item -ItemType Directory -Force $destination | Out-Null
$cues = @{
  welcome = 'Bienvenue au Salon des Prétendants. Bonne chance à tous.'
  deal = 'Les jeux commencent. Distribution des cartes.'
  flop = 'Le flop.'
  turn = 'La turn.'
  river = 'La river.'
  showdown = 'Abattage des cartes.'
  victory = 'Félicitations. Vous êtes qualifié pour le futur Grand Poks Casino 3D.'
}
try {
  foreach ($cue in $cues.GetEnumerator()) {
    $synth.SetOutputToWaveFile((Join-Path $destination ($cue.Key + '.wav')))
    $synth.Speak($cue.Value)
    $synth.SetOutputToNull()
  }
} finally { $synth.Dispose() }
Write-Host 'Voix française locale générée. Unity importera les WAV à la prochaine ouverture.'
