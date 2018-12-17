push_footnotes_below_lines = function (head)
   for item in node.traverse_id(node.id("whatsit"), head) do
      local is_footnote = node.has_attribute(item, 100)
      if is_footnote
      then
--         texio.write_nl("Found a Footnote!!!" .. is_footnote)
         while item do
            local footnote = node.copy(tex.box[is_footnote])
            head, new = node.insert_before(head,item,footnote)
            node.set_attribute(new,200,is_footnote)
            item = item.next
         end
         head = node.remove(head, item)
      end
   end
   return head
end

crush_footnotebox = function (head)
   local vbox = node.copy(tex.box.vfillbox)
   local tail = head.tail
   node.insert_after(head,tail,vbox)
   for item in node.traverse(head) do
      local footnotebox = node.has_attribute(item,200)
      if footnotebox
      then
         head = node.remove(head,item)
         node.insert_before(head,tail,tex.box[footnotebox])
      end
   end
   return true
end

