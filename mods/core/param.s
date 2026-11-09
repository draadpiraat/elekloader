| SPDX-License-Identifier: GPL-2.0-or-later
| core 4.4 (Digitakt mk1): ev_param_step, the step a knob turn adds, as
| core-dn1's (5.4) on the Digitone. Last in sources, so the code before it
| keeps its place. The addresses are the same in OS 1.53 and 1.54:
|   SHOWN_FN  the page views' value of a parameter, a held step's lock first:
|             f(view, id, uint8_t *locked) -> 8.8
|
| The page views' encoder handler (0x40032a78) has the turn's knob in d3 and
| its parameter in d2, and gets the step from 0x400c06ae (8.8, acceleration
| in). At 0x40032bc4 it pops that call's arguments and keeps the step in d5,
| `lea 20(sp),sp; move.l d0,d5`, then branches on it (0: no edit). Every
| edit after that adds d5: the sound's (view +88), GRID REC's held steps'
| locks (+124) and +92's. Core takes those six bytes: the same, then each
| handler of ev_param_step in turn,
|   int32_t f(void *view, int32_t id, int32_t delta, int32_t knob, int32_t value)
| -> the step to add (delta itself to leave it; 0 adds nothing), each
| handler getting the one before it left. value is what the turn starts
| from (SHOWN_FN): the held step's lock with steps held, else the sound's.
| The stock then edits, clamps and shows its pop-up as for any turn. The UI
| task.

        .section .run, "ax"
        .globl  core_param_step
core_param_step:
        move.l  (%sp), 20(%sp)          | lea 20(sp),sp, under our return
        lea     20(%sp), %sp
        move.l  %d0, %d5                | the step: the move the jsr replaced
        beq.s   9f                      | none: the stock makes no edit
        tst.l   ev_param_step
        beq.s   9f
        move.l  %a3, -(%sp)
        clr.l   -(%sp)                  | the getter's locked byte, then the value
        pea     (%sp)
        move.l  %d2, -(%sp)             | the id
        move.l  %a2, -(%sp)             | the view
        jsr     SHOWN_FN
        lea     12(%sp), %sp
        move.l  %d0, (%sp)
        lea     ev_param_step, %a3
1:      move.l  (%a3)+, %d0
        beq.s   2f
        move.l  (%sp), -(%sp)           | the value
        move.l  %d3, -(%sp)             | the knob
        move.l  %d5, -(%sp)             | the step
        move.l  %d2, -(%sp)             | the id
        move.l  %a2, -(%sp)             | the view
        movea.l %d0, %a0
        jsr     (%a0)
        lea     20(%sp), %sp
        move.l  %d0, %d5
        bra.s   1b
2:      addq.l  #4, %sp
        movea.l (%sp)+, %a3
9:      tst.l   %d5                     | the flags the move left; rts keeps them
        rts
