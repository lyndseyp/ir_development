.irq1 timer_interrupt

timer_interrupt:
  load a, 0 ; load the counter into a
  incr a, a ; increment a
  store 0, a ; store a back in the counter

  immd b, A ; set b to 0xA (10)
  breq reset ; if the counter is 10 goto reset
  idle

reset:
  immd a, 0
  store 0, a
  goto incr_state

incr_state:
  load a, 1
  incr a, a
  store 1, a

  immd b, 1
  breq forward ; if a == 1 forward
  immd b, 2
  breq back ; if a == 2 back
  immd b, 3
  breq fwdleft ; if a == 3 forward left
  immd b, 4
  breq bckrght ; if a == 4 back right
  immd b, 5
  breq fwdrght ; if a == 5 forward right
  immd b, 6
  breq bckleft ; if a == 6 back left
  immd b, 7
  breq stop
  idle

forward:
  immd a, 1
  store 90, a
  idle

back:
  immd a, 2
  store 90, a
  idle

fwdleft:
  immd a, 3
  store 90, a
  idle

bckrght:
  immd a, 4
  store 90, a
  idle

fwdrght:
  immd a, 5
  store 90, a
  idle

bckleft:
  immd a, 6
  store 90, a
  idle

stop:
  immd a, 7
  store 90, a
  idle
