import random
from mpf.core.mode import Mode


TARGET_ORDER = ['HOMER', 'MARGE', 'BART', 'LISA', 'MAGGIE']


class VideoCouchShuffle(Mode):
    """
    Gestion de l'état du video mode couch_shuffle côté MPF.

    Etat :
      _positions : liste des 5 personnages dans leur position actuelle
      _cursor    : index de la position sélectionnée (0-4)
      _held      : index de la position "en main" (None si rien sélectionné)

    Events entrants (depuis gmc.cfg / GMC) :
      video_mode_left   -> déplace le curseur à gauche
      video_mode_right  -> déplace le curseur à droite
      video_mode_action -> sélectionne ou échange

    Events sortants (vers GMC / logs MPF) :
      video_couch_shuffle_state    (positions, cursor, held)
      video_couch_shuffle_select   (cursor, character)
      video_couch_shuffle_pick     (position, character)
      video_couch_shuffle_swap     (pos_a, pos_b, positions)
      video_couch_shuffle_success
      video_couch_shuffle_finished
    """

    def mode_start(self, **kwargs):
        self._positions = list(TARGET_ORDER)
        while self._positions == TARGET_ORDER:
            random.shuffle(self._positions)

        self._cursor = 0
        self._held = None

        self.add_mode_event_handler('video_mode_left', self._handle_left)
        self.add_mode_event_handler('video_mode_right', self._handle_right)
        self.add_mode_event_handler('video_mode_action', self._handle_action)

        self._post_state()

    def _post_state(self):
        self.machine.events.post(
            'video_couch_shuffle_state',
            positions=','.join(self._positions),
            cursor=self._cursor,
            held=self._held if self._held is not None else -1
        )

    def _handle_left(self, **kwargs):
        self._cursor = (self._cursor - 1) % 5
        self.machine.events.post(
            'video_couch_shuffle_select',
            cursor=self._cursor,
            character=self._positions[self._cursor]
        )
        self._post_state()

    def _handle_right(self, **kwargs):
        self._cursor = (self._cursor + 1) % 5
        self.machine.events.post(
            'video_couch_shuffle_select',
            cursor=self._cursor,
            character=self._positions[self._cursor]
        )
        self._post_state()

    def _handle_action(self, **kwargs):
        if self._held is None:
            # Premier appui : on prend le personnage sous le curseur
            self._held = self._cursor
            self.machine.events.post(
                'video_couch_shuffle_pick',
                position=self._cursor,
                character=self._positions[self._cursor]
            )
            self._post_state()
        else:
            # Deuxième appui : on échange les deux positions
            pos_a, pos_b = self._held, self._cursor
            self._positions[pos_a], self._positions[pos_b] = (
                self._positions[pos_b], self._positions[pos_a]
            )
            self._held = None
            self.machine.events.post(
                'video_couch_shuffle_swap',
                pos_a=pos_a,
                pos_b=pos_b,
                positions=','.join(self._positions)
            )
            self._post_state()
            self._check_complete()

    def _check_complete(self):
        if self._positions == TARGET_ORDER:
            self.machine.events.post('video_couch_shuffle_success')
            self.machine.events.post('video_couch_shuffle_finished')
